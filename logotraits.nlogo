extensions[rnd]

globals[

  nr-bare-per-type        ; list where each item has the amount of bare soil patches per each patch type.
                          ; this is used in perturbations to calculate how many patches of the newly generated map should be assigned to
                          ; bare cover to keep the total number of bare patches unaffected when the perturbation occurs.
  ;stats
  initial-type-1-patches  ; number of initial type-1-patches
  initial-type-2-patches  ; number of initial type-2-patches
  initial-type-3-patches  ; number of initial type-3-patches
  initial-type-4-patches  ; number of initial type-4-patches
  die-of-starvation       ; how many agents die of starvation
  die-of-randomness       ; how many agents die of old age
  mean-energy-specialists ; mean energy of specialists
  mean-energy-generalists ; mean energy of generalists
  nr-generalists          ; # of generalists
  nr-specialists          ; # of specialists
  nr-specialists/total    ; ratio between specialists and total
  energy-specialists      ; total energy in specialists
  energy-generalists      ; total energy in generalists
  energyS_energyT         ; ratio between energy of specialists and total
  deaths-per-patch-type   ; list in which each element is a list with the number of the cover, the number of dead generalists and dead specialists.
  run-duration             ; the amount of time that "go" took.

  ;visualisation
  palette ; list of colors of patches
]

breed[specialists specialist]
breed[generalists generalist]

patches-own [
  cover-type         ; cover type 0 means no cover-type at all. 1 is the cover type that specialists and generalists eat and 2 < are optional and only eaten by generalists.
  cover-memory       ; stores information about what was the last cover-type of a patch. Useful to make it grow back to the original in static worlds
                     ;   where the patches always regrow to their cover-memory value when eaten unless perturbations changes their identity.
  neighbors-identity ; a list of neighbors by type of neighbor, where neighbors-identity[0] are the number of patches with cover type 0 in the neighborhood of self.
  initialized?       ; used to distinguish patches which were already assigned a cover-type during setup from those that weren't.

  ; stats
  deaths-here        ; list of deaths that took place at this spot, in specialists and generalists
]

turtles-own[
  energy                     ; energy of agent
  age                        ; age of agent
  hungry?                    ; whether the agent should search for food (if it's hungry) or not
  timeSinceLastReproduction  ; how many ticks have passed since the last time this has reproduced
  feeding-efficiency;        ; which fraction of energy-per-food can the agent actually convert to energy
  feeding-selectivity        ; # of types of cover can the agent eat
  energy-per-food;           ; amount of energy that a patch grants (max)
  death-probability          ; age limit of the agent
]

;;----------------------------------------------------------
;; MAIN
;;----------------------------------------------------------

to go
  if ticks >= max-nr-of-ticks or count specialists <= 0 or count generalists <= 0[
    set run-duration timer
    collect-final-data
    stop
  ]
  ifelse static-cover-mode?
  [cover-regrowth
    add-perturbation] ; currently perturbations only work in static cover mode
  [cover-growth colonization-success-rate]
  agents-go
  collect-data
  tick
end

to setup
  clear-all
  setup-constants-and-globals
  setup-patches patchiness nr-type1/nr-type2
  if static-cover-mode?
  [expand-cover-type] ; the cover will grow completely before the experiment begins
  setup-agents
  collect-cover-data
  reset-ticks
  reset-timer
end

;;-----------------------------------------------------------
;; AGENTS
;;-----------------------------------------------------------

; agents are initialized
to setup-agents
  create-generalists initial-generalists
  [
    set-common-atributes
    set-generalist-atributes
  ]
  create-specialists initial-specialists [
    set-common-atributes
    set-specialist-atributes
  ]
end

; common attributes to all agents are set with this procedure
to set-common-atributes
  set age random maturity-age
  set death-probability mortality-rate
  set energy 10 + random (energy-to-reproduce - 10)
  set xcor random-xcor
  set ycor random-ycor
  set shape "bug"
  set hungry? true
end

; attributes common to all generalists are set with this procedure-
; Generalists are not very selective (they can eat from several different patches),
; but their feeding efficiency is inversely proportional to the number of cover-types
; they can eat.
to set-generalist-atributes
  set color magenta
  set feeding-selectivity nr-cover-types
  set feeding-efficiency (1 / feeding-selectivity)
  set energy-per-food feeding-efficiency * food-energy-value
end

; attributes common to all specialists are set with this procedure.
; Specialists are very selective in their patches but their feeding-efficiency
; is higher than the generalists'.
to set-specialist-atributes
  set color cyan
  set feeding-selectivity 1
  set feeding-efficiency specialist-efficiency-coefficient
  set energy-per-food feeding-efficiency * food-energy-value
end

to agents-go
  ask turtles [
    maybeDieOfRandomness
    updateHungerStatus
    ifelse hungry? [
      toSearch
      toConsumeOrMaybeDie
    ]
    ;else
    [
      if age > maturity-age and timeSinceLastReproduction >= interbirthInterval [
        ifelse energy = energy-to-reproduce [
          toReproduce
          set timeSinceLastReproduction 0
        ]
        ;else
        [
          toSearch
          toConsumeOrMaybeDie
        ]
      ]
    ]
    toAge
    toMaintain
  ]
end
; top procedure for agents.
to agents-go-old
  ask turtles [

    ifelse energy > energy-to-reproduce [
      if age > maturity-age [
        toReproduce
      ]
    ]
    ;else
    [
      toSearch
      ;toConsume
    ]
    toMaintain
    toAge
    ;toDie
  ]
end


;agent moves.
to toSearch
  ifelse searches-for-food? [     ; user input: does the agent search for food?
    move-to-food
  ]
  ;else
  [
    ifelse biased-forward-moving? ; user input: does the agent tend to move forward?
    [front-biased-move]
    ;else
    [full-random-move]            ; or just randomly?
  ]
end

to toMaintain ; cost of maintaining a living body
  set energy energy - 1
end

; agent moves toward one of patches with edible cover-type
to move-to-food
  ifelse any? neighbors with
  [ cover-type > 0 and cover-type <= [feeding-selectivity] of myself ] ; agent moves to neighbor only if the cover type is appropriate to it
    [
      let good-patch one-of neighbors with [ cover-type > 0 and cover-type <= [feeding-selectivity] of myself]
      face good-patch
      move-to good-patch
    ]
      ;else
    [
      ifelse biased-forward-moving?  ;otherwise it will just move without thinking about food
      [front-biased-move]
      ;else
      [full-random-move]
    ]
end

; the agent moves with completely random movement
to full-random-move
  set heading random 360
  fd movement-speed
end

; the agent moves but with a slight bias in
; preserving the last heading
to front-biased-move
  set heading heading + random 180 - random 180 ;i think it should work fine now
  fd movement-speed
end

; the agent inspects if patch is eatable and if it can eat it.
to toConsumeOrMaybeDie
  let can-i-eat? False
  ask patch-here [
    ifelse cover-type > 0 and cover-type <= [feeding-selectivity] of myself [
      set can-i-eat? True
      set cover-type 0
    ]
    ;else
    [
      ask myself [
        maybeDieOfStarvation
      ]
    ]
  ]
  if can-i-eat? = True [
    set energy energy + energy-per-food
  ]
end

; the agent reproduces if it has enough energy and if it has reached maturity already.
to toReproduce
  let new-energy energy / 2
  let hatchlings 1
  if diesOnReproduction? = true [
    set hatchlings 2
  ]
  hatch hatchlings
    [ set energy new-energy set age 0 ]  ; gives half of its energy to the new agent and
  if diesOnReproduction? = true [
    die
  ]
  set energy new-energy                ; loses half of its energy
end

; age increments by 1
to toAge
  set age age + 1
  set timeSinceLastReproduction timeSinceLastReproduction + 1
end

; if agent is too old or has no energy it dies
to maybeDieOfStarvation
  if energy <= 1
    [
      set die-of-starvation die-of-starvation + 1  ; one more death due to starvation
      inform-patch-of-death
      die
    ]
end

; the agent checks whether it's gonna die this round.
to maybeDieOfRandomness
  if random-float 1 < death-probability
    [
      set die-of-randomness die-of-randomness + 1    ; one more death due to old age
      inform-patch-of-death
      die
    ]
  ;lives
end

;the patch increments deaths-here by 1 at position 0 (for specialist) or 1 (for generalist)
to inform-patch-of-death
  let pos 0 ; for specialists
  if (is-generalist? self )
  [set pos 1] ;unless it's a generalist
  ask patch-here
  [
    set deaths-here replace-item pos deaths-here (item pos deaths-here + 1)
    let total-deaths item cover-memory deaths-per-patch-type
    let nr-total-pos-deaths item pos total-deaths
    set nr-total-pos-deaths nr-total-pos-deaths + 1
    set total-deaths replace-item pos total-deaths nr-total-pos-deaths
    set deaths-per-patch-type replace-item cover-memory deaths-per-patch-type total-deaths
  ]
end

; checks if the agent is hungry or not.
to updateHungerStatus
  ifelse energy >= energy-to-reproduce ; if energy is higher than the energy to reproduce, then
  [
    set energy energy-to-reproduce
    set hungry? false
  ]
  [
    if energy < hungerThreshold
    [
      set hungry? true
    ]
  ]
end
;;-----------------------------------------------------------
;; PATCHES
;;-----------------------------------------------------------
; Starting conditions for patches.
;
; Args:
; param bare-soil-% : value between 0 and 100 that gives the ratio of patches that won't be assigned
;   any cover type other than bare cover type at this point. The higher this value, the less patches will
;   be assigned to a cover-type higher than 0 ( 0 is bare soil) and thus the degree of patchiness
;   will higher, since individual patches will have the opportunity to grow since there's more bare soil.
; param #type1-ratio: how many patches of type 1 should there be for each of patch 2.
to setup-patches [bare-soil-% type1-ratio]
  ask patches
  [
    set initialized? false
    reset-neighbors-identity ; to put the counters at zero
    set deaths-here n-values (nr-cover-types) [0]
  ]
  let initial-bare round (bare-soil-% / 100 * count patches)
  ask n-of initial-bare patches
    [
      set cover-type 0
      set initialized? true
      update-cover-display
    ]
  ; atribute patches to cover-type 1: the one that is eaten by specialists.
  ; type 1 ratio gives the ratio of type-1 patches related to any other type.
  ; Example: at a ratio of 2, in 300 patches and 3 cover-types, 150 are of type 1,
  ; 75 of type 2 and 75 of type 3. To check how many will be attributed to type 1
  ; and the remaining types, we divide the number of non-initialized patches by
  ; nr-cover-types - 1 + type1-ratio. The result should be the #-of-any-other-type and
  ; #any-other-type * type1-ratio the #-of-type1.

  ; if there is only one cover-type it makes no sense that type1 has any ratio other than 1.
  if nr-cover-types <= 1 [
    set type1-ratio 1
  ]
  let #remaining count patches - initial-bare
  let #any-other-type #remaining / (nr-cover-types - 1 + type1-ratio)
  let #type1 #any-other-type * type1-ratio

  let p 1
  ask n-of #type1 patches with [initialized? = false][
    set cover-type p
    set initialized? true
    set cover-memory p
    update-cover-display
  ]
  set p p + 1

  ; this part will only work if the nr-cover-types is higher than 1
  while [ p <= nr-cover-types ]
  [
    ask n-of #any-other-type patches with [initialized? = false]
      [
        set cover-type p
        set initialized? true
        set cover-memory p
        update-cover-display
      ]
    set p p + 1
  ]
end

; Updates the list of neighbors by type
to update-neighbors-identity
  ask patches with [ cover-type = 0 ] [
    reset-neighbors-identity
    ask neighbors
    [
      let c cover-type
      ask myself
      [
        set neighbors-identity
        replace-item  c neighbors-identity
        (item c neighbors-identity + 1) ;increment the list
      ]
    ]
  ]
end

to reset-neighbors-identity
  set neighbors-identity n-values (nr-cover-types + 1) [0]
end

; expand cover-type before the agents are put in the world
to expand-cover-type
  while [count patches with [ cover-type = 0 ]  > 0 ] [
    cover-growth 1
  ]
end

to cover-growth [ rate ]
  update-neighbors-identity
  ask patches with [cover-type = 0]
  [
    ;test
    ;let true-color pcolor
    ;set pcolor red
    ;end test
    let total 0
    ;print (word "Patch:" self " has the neigborhood:" neighbors-identity)
    foreach neighbors-identity
    [ [x]-> set total total + x

    ]
    if total > 0 ;;If there is neighbours with cover types different from 0
    [
      let weighted-list []
      let i 0
      foreach neighbors-identity
      [ [x]->
        set weighted-list lput (list i  (x / total)) weighted-list
        set i i + 1
      ]
      ;print (word "Patch" self " has weighted-list:" weighted-list)
      let element-type rnd:weighted-one-of-list weighted-list [[z]-> last z]
      let chosen-type first element-type
      let val random-float 1
      if val < item (chosen-type) neighbors-identity  * rate
      [
        if chosen-type > 0 [
          set cover-type chosen-type
          set cover-memory chosen-type
        ]
      ]
    ]

     ;test
     ;set pcolor true-color
     ;end test
    update-cover-display
  ]
end


;cover regrows instead of growing sideways. to be used when keep-cover-start-locations? is true.
to cover-regrowth
  ask patches with [cover-type = 0]
  [
    if random-float 1 < colonization-success-rate
    [
      set cover-type cover-memory
    ]
    update-cover-display
  ]
end

to remove-some-cover
  let i 1
  while [ i <= nr-cover-types ]
  [
    ask n-of item (i - 1) nr-bare-per-type patches
    [set cover-type 0]
    set i i + 1
  ]
end

; adds perturbation ? ticks.
to add-perturbation
  if perturbation-frequency > 0 [
    if ticks mod perturbation-frequency = 0
    [
      update-bare-per-type
      setup-patches patchiness nr-type1/nr-type2
      expand-cover-type
      remove-some-cover
    ]
  ]
end

;;----------------------------------------------------------
;; DATA, VARIABLES AND CONSTANTS
;;----------------------------------------------------------

to collect-data
  set nr-generalists count generalists
  set nr-specialists count specialists

end

to update-bare-per-type
  set nr-bare-per-type n-values (nr-cover-types + 1) [0]
  let i 1
  while [i <= nr-cover-types]
  [
    set nr-bare-per-type
    replace-item (i - 1) nr-bare-per-type count patches with [cover-type = 0  and cover-memory = i]
    set i i + 1
  ]
end

to setup-constants-and-globals
  set die-of-starvation 0
  set die-of-randomness 0
  set palette [brown green yellow orange blue red magenta violet lime]
  set deaths-per-patch-type []
  repeat (nr-cover-types + 1)
  [
    set deaths-per-patch-type lput (list 0 0) deaths-per-patch-type
  ]
end

to collect-cover-data
  set initial-type-1-patches count patches with [cover-memory = 1] ; number of initial type-1-patches
  set initial-type-2-patches count patches with [cover-memory = 2] ; number of initial type-2-patches
  set initial-type-3-patches count patches with [cover-memory = 3] ; number of initial type-3-patches
  set initial-type-4-patches count patches with [cover-memory = 4] ; number of initial type-4-patches
end


to collect-final-data
  collect-data
  if collect-energy-means? [
    ifelse (nr-generalists > 0 ) [
      set mean-energy-generalists mean [energy] of generalists
    ]
    [set mean-energy-generalists 0]
    ifelse (nr-specialists > 0) [
      set mean-energy-specialists mean [energy] of specialists
    ]
    [set mean-energy-specialists 0]
  ]
  ifelse count turtles > 0
  [set nr-specialists/total nr-specialists / count turtles]
  [set nr-specialists/total -1] ; if there are no individuals it's better that we know that

  set energy-specialists sum [energy] of specialists
  set energy-generalists sum [energy] of generalists

end


;;-----------------------------------------------------------
;; DISPLAY
;;-----------------------------------------------------------



to update-cover-display
    set pcolor item cover-type palette
end

to update-display
  update-cover-display
end
@#$#@#$#@
GRAPHICS-WINDOW
533
10
1029
507
-1
-1
8.0
1
10
1
1
1
0
1
1
1
-30
30
-30
30
0
0
1
ticks
30.0

BUTTON
1036
169
1099
202
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
1036
206
1099
239
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
4
304
143
337
initial-specialists
initial-specialists
0
100
20.0
1
1
NIL
HORIZONTAL

SLIDER
5
338
144
371
initial-generalists
initial-generalists
0
100
20.0
1
1
NIL
HORIZONTAL

SLIDER
4
272
144
305
energy-to-reproduce
energy-to-reproduce
0
200
60.0
1
1
NIL
HORIZONTAL

PLOT
257
161
524
311
number of turles and resources
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"generalists" 1.0 0 -5825686 true "" "plot count generalists"
"specialists" 1.0 0 -12345184 true "" "plot count specialists"

SLIDER
313
417
507
450
nr-cover-types
nr-cover-types
1
5
2.0
1
1
NIL
HORIZONTAL

SLIDER
313
385
507
418
patchiness
patchiness
0
99.99
99.9
0.01
1
NIL
HORIZONTAL

SLIDER
313
353
507
386
colonization-success-rate
colonization-success-rate
0
1
0.1
0.01
1
NIL
HORIZONTAL

PLOT
258
10
523
160
cover balance
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -6459832 true "" "plot count patches with [cover-type = 0]"
"pen-1" 1.0 0 -10899396 true "" "plot count patches with [cover-type = 1]"
"pen-2" 1.0 0 -1184463 true "" "plot count patches with [cover-type = 2]"
"pen-3" 1.0 0 -955883 true "" "plot count patches with [cover-type = 3]"
"pen-4" 1.0 0 -13345367 true "" "plot count patches with [cover-type = 4]"
"pen-5" 1.0 0 -2674135 true "" "plot count patches with [cover-type = 5]"

SLIDER
313
483
448
516
food-energy-value
food-energy-value
0
100
10.0
1
1
NIL
HORIZONTAL

MONITOR
192
121
249
166
turtles
count turtles
0
1
11

BUTTON
1100
170
1163
203
NIL
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
6
370
145
403
maturity-age
maturity-age
0
300
40.0
5
1
NIL
HORIZONTAL

SWITCH
1036
29
1225
62
biased-forward-moving?
biased-forward-moving?
1
1
-1000

SWITCH
1036
63
1198
96
searches-for-food?
searches-for-food?
0
1
-1000

MONITOR
118
167
187
212
specialists
nr-specialists
0
1
11

MONITOR
118
121
191
166
generalists
nr-generalists
0
1
11

SWITCH
1034
129
1242
162
static-cover-mode?
static-cover-mode?
0
1
-1000

SLIDER
1038
294
1233
327
perturbation-frequency
perturbation-frequency
0
1000
0.0
50
1
NIL
HORIZONTAL

MONITOR
6
167
117
212
energy specialists
mean-energy-specialists
1
1
11

MONITOR
6
121
117
166
energy generalists
mean-energy-generalists
1
1
11

MONITOR
8
18
65
63
cover1
count patches with [ cover-type = 1 ]
17
1
11

MONITOR
65
18
122
63
cover2
count patches with [ cover-type = 2 ]
17
1
11

MONITOR
122
18
179
63
cover3
count patches with [ cover-type = 3 ]
17
1
11

MONITOR
8
63
65
108
cover4
count patches with [ cover-type = 4 ]
17
1
11

BUTTON
1067
346
1165
379
NIL
clear-turtles
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
313
450
507
483
nr-type1/nr-type2
nr-type1/nr-type2
0.01
500
1.0
0.01
1
NIL
HORIZONTAL

TEXTBOX
335
333
382
351
patches
11
0.0
1

MONITOR
66
62
119
107
cover5
count patches with [cover-type = 5]
17
1
11

TEXTBOX
15
247
61
265
agents
11
0.0
1

TEXTBOX
1050
10
1216
38
I'm considering to take these out
11
0.0
1

SLIDER
5
402
145
435
specialist-efficiency-coefficient
specialist-efficiency-coefficient
0
10
1.0
0.1
1
NIL
HORIZONTAL

CHOOSER
1043
391
1206
436
display-type
display-type
"cover-type" "specialist-deaths" "generalist-deaths"
0

PLOT
536
518
736
668
deaths per patch type 1
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"dead specialists patch-type 1" 1.0 0 -11221820 true "" "plot (item 0 (item 1 deaths-per-patch-type) / (ticks + 1))"
"dead generalists ct 1" 1.0 0 -5825686 true "" "plot (item 1 (item 1 deaths-per-patch-type) / (ticks + 1))"

PLOT
738
518
938
668
deaths per patch type 2
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"specialists" 1.0 0 -11221820 true "" "plot (item 0 (item 2 deaths-per-patch-type) / (ticks + 1))"
"generalists" 1.0 0 -5825686 true "" "plot (item 1 (item 2 deaths-per-patch-type)  / (ticks + 1))"

SLIDER
284
604
456
637
max-nr-of-ticks
max-nr-of-ticks
0
50000
2000.0
100
1
NIL
HORIZONTAL

SWITCH
286
567
491
600
collect-energy-means?
collect-energy-means?
0
1
-1000

SLIDER
5
436
177
469
mortality-rate
mortality-rate
0
1
0.001
0.001
1
NIL
HORIZONTAL

PLOT
982
526
1304
710
death cause
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"starv" 1.0 0 -16777216 true "" "plot (die-of-starvation / (die-of-randomness + die-of-starvation))"

OUTPUT
1319
299
1559
353
13

MONITOR
11
664
151
709
total energy specialists
energy-specialists
17
1
11

MONITOR
11
711
155
756
total energy generalists
energy-generalists
17
1
11

SLIDER
5
468
177
501
movement-speed
movement-speed
0
2
1.0
0.1
1
NIL
HORIZONTAL

SLIDER
7
506
179
539
interbirthInterval
interbirthInterval
1
100
20.0
1
1
NIL
HORIZONTAL

SWITCH
7
539
202
572
diesOnReproduction?
diesOnReproduction?
1
1
-1000

MONITOR
329
696
411
741
NIL
run-duration
17
1
11

SLIDER
7
573
179
606
hungerThreshold
hungerThreshold
0
energy-to-reproduce
30.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## Purpose

(a general understanding of what the model is trying to show or explain)

## Entities, state variables, scales

(what rules the agents use to create the overall behavior of the model)

## Process overview and scheduling

(how to use the model, including a description of each of the items in the Interface tab)

## Design concepts

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.3
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="test patchiness" repetitions="2" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>nr-specialists/total</metric>
    <metric>nr-generalists</metric>
    <metric>nr-specialists</metric>
    <metric>count patches with [cover-memory = 1]</metric>
    <metric>count patches with [cover-memory = 2]</metric>
    <metric>item 0 (item 1 deaths-per-patch-type)</metric>
    <metric>item 1 (item 1 deaths-per-patch-type)</metric>
    <metric>item 0 (item 2 deaths-per-patch-type)</metric>
    <metric>item 1 (item 2 deaths-per-patch-type)</metric>
    <enumeratedValueSet variable="colonization-success-rate">
      <value value="0.14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perturbation-frequency">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-generalists">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-specialists">
      <value value="20"/>
    </enumeratedValueSet>
    <steppedValueSet variable="patchiness" first="0.7" step="1" last="99.7"/>
    <enumeratedValueSet variable="energy-to-reproduce">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="specialist-efficiency-coefficient">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="biased-forward-moving?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maturity-age">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food-energy-value">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="searches-for-food?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nr-type1/nr-type2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nr-cover-types">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="static-cover-mode?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="display-type">
      <value value="&quot;cover-type&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="limits" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>nr-specialists/total</metric>
    <metric>ticks</metric>
    <enumeratedValueSet variable="colonization-success-rate">
      <value value="0.001"/>
      <value value="0.01"/>
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perturbation-frequency">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-generalists">
      <value value="2"/>
      <value value="20"/>
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-specialists">
      <value value="2"/>
      <value value="20"/>
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nr-type1/nr-type2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="patchiness">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energy-to-reproduce">
      <value value="2"/>
      <value value="20"/>
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="specialist-efficiency-coefficient">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="biased-forward-moving?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maturity-age">
      <value value="1"/>
      <value value="10"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food-energy-value">
      <value value="4"/>
      <value value="40"/>
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="searches-for-food?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nr-cover-types">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-nr-of-ticks">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="static-cover-mode?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="display-type">
      <value value="&quot;cover-type&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="version 1.1_robustness" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <metric>initial-type-1-patches</metric>
    <metric>initial-type-2-patches</metric>
    <metric>initial-type-3-patches</metric>
    <metric>initial-type-4-patches</metric>
    <metric>die-of-starvation</metric>
    <metric>die-of-randomness</metric>
    <metric>mean-energy-specialists</metric>
    <metric>mean-energy-generalists</metric>
    <metric>nr-generalists</metric>
    <metric>nr-specialists</metric>
    <metric>nr-specialists/total</metric>
    <metric>energy-specialists</metric>
    <metric>energy-generalists</metric>
    <metric>energyS_energyT</metric>
    <metric>deaths-per-patch-type</metric>
    <metric>run-duration</metric>
    <enumeratedValueSet variable="movement-speed">
      <value value="0.5"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonization-success-rate">
      <value value="0.01"/>
      <value value="0.05"/>
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perturbation-frequency">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-generalists">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-specialists">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nr-type1/nr-type2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="patchiness">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energy-to-reproduce">
      <value value="10"/>
      <value value="20"/>
      <value value="40"/>
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="specialist-efficiency-coefficient">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="biased-forward-moving?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maturity-age">
      <value value="0"/>
      <value value="20"/>
      <value value="40"/>
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food-energy-value">
      <value value="10"/>
      <value value="20"/>
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="searches-for-food?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nr-cover-types">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="static-cover-mode?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mortality-rate">
      <value value="0"/>
      <value value="0.001"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-nr-of-ticks">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="display-type">
      <value value="&quot;cover-type&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="collect-energy-means?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="version 1.2_robustness" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <metric>initial-type-1-patches</metric>
    <metric>initial-type-2-patches</metric>
    <metric>initial-type-3-patches</metric>
    <metric>initial-type-4-patches</metric>
    <metric>die-of-starvation</metric>
    <metric>die-of-randomness</metric>
    <metric>mean-energy-specialists</metric>
    <metric>mean-energy-generalists</metric>
    <metric>nr-generalists</metric>
    <metric>nr-specialists</metric>
    <metric>nr-specialists/total</metric>
    <metric>energy-specialists</metric>
    <metric>energy-generalists</metric>
    <metric>energyS_energyT</metric>
    <metric>deaths-per-patch-type</metric>
    <metric>run-duration</metric>
    <enumeratedValueSet variable="movement-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonization-success-rate">
      <value value="0.01"/>
      <value value="0.05"/>
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perturbation-frequency">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-generalists">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-specialists">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nr-type1/nr-type2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="patchiness">
      <value value="99.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energy-to-reproduce">
      <value value="30"/>
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="specialist-efficiency-coefficient">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="biased-forward-moving?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maturity-age">
      <value value="0"/>
      <value value="20"/>
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food-energy-value">
      <value value="10"/>
      <value value="20"/>
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="searches-for-food?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nr-cover-types">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="static-cover-mode?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mortality-rate">
      <value value="0"/>
      <value value="0.001"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-nr-of-ticks">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="display-type">
      <value value="&quot;cover-type&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="collect-energy-means?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diesOnReproduction?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hungerThreshold">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="interbirthInterval">
      <value value="0"/>
      <value value="10"/>
      <value value="20"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
