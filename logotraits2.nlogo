extensions[ csv ]


globals[
  ; LANDSCAPE GENERATION
  ; num-of-seeds-per-type
  ; num-of-patch-types
    patch-palette                  ; the colours of the patches

  ; PATCHES
  ; PATCHES PARAMETERS
  ;


  ; in test
  ;mortality-rate
  ongoing-indirect-perturbation?

  ; STATS
  number-of-initial-lineages-remaining

]

turtles-own[
  ; FOCAL TRAITS
  body-size
  interbirth-interval
  fecundity
  maturity-age
  longevity
  habitat-spec
  sexual?
  disp-ability
  disp-stage

  ; NON-FOCAL TRAITS
  energy
  age
  basal-dispersal-cost-per-unit
  basal-growth-cost-per-tick
  basal-homeostasis-cost-per-tick
  basal-resource-intake
  energy-to-reproduce
  energy-after-reprod
  ticks-since-last-reproduction
  reproduction-cost

  ;stats
  lineage-identity
  standardized-ear
  standardized-etr

  realized-maturity-age
  realized-fecundity
  realized-dispersal-ability
  realized-interbirth-interval

]

patches-own[
  resource-type
  resources
  max-resources
  resource-regen

  original-resources
  original-max-resources
  original-resource-regen

  under-i-perturbation?
  under-d-perturbation?

  ; visualization
  base-color
]

breed [organisms1 organism1]
breed [organisms2 organism2]

; Import world parameters
to set-world-parameters

  set-patch-size patch-n-pixels
  resize-world min-xcor max-xcor min-ycor max-ycor

end

to setup
  ;random-seed 55
  clear-all
  reset-ticks
  set-world-parameters
  generate-map
  set ongoing-indirect-perturbation? false
  ;initialize patches
  ask patches [
    set resources starting-resources
    set max-resources starting-max-resources
    set resource-regen starting-resource-regen

    set original-resources resources
    set original-max-resources max-resources
    set original-resource-regen resource-regen

    set under-i-perturbation? false
    set under-d-perturbation? false
  ]

  ;create organisms1
  create-organisms1 starting-no
  [

    ; FOCAL TRAITS
    set color yellow
    set body-size starting-body-size
    set interbirth-interval starting-interbirth-interval
    set fecundity starting-fecundity
    set maturity-age starting-maturity-age
    set longevity maturity-longevity-coefficient * maturity-age
    ;set habitat-spec csv:from-row starting-habitat-spec
    set habitat-spec [1 0 0 0]
    set sexual? starting-sexual?
    set disp-ability starting-disp-ability
    set disp-stage csv:from-row starting-disp-stage

    ; INITIAL ENERGY AND AGE AND SPATIAL CORDINATES
    set xcor random-xcor
    set ycor random-ycor
    set energy starting-energy * (body-size ^ metabolic-allometric-exponent)
    set age starting-age

    ; * BODY-SIZE ^ allometric-constant TRAITS
    set basal-dispersal-cost-per-unit starting-basal-dispersal-cost-per-unit * (body-size ^ metabolic-allometric-exponent)
    set basal-growth-cost-per-tick starting-basal-growth-cost-per-tick * (body-size ^ metabolic-allometric-exponent)
    set basal-homeostasis-cost-per-tick starting-basal-homeostasis-cost-per-tick * (body-size ^ metabolic-allometric-exponent)
    set basal-resource-intake starting-basal-resource-intake * (body-size ^ metabolic-allometric-exponent)

    ; BODY-SIZE SCALING TRAITS (but not allometrically
    set energy-to-reproduce starting-ratio-energy-to-reproduce * (body-size ^ metabolic-allometric-exponent)
    set energy-after-reprod starting-ratio-energy-after-reprod * (body-size ^ metabolic-allometric-exponent)
    set ticks-since-last-reproduction 0 ; high value so that organisms automatically reproduce when they can the first time ; now it~s low value
    set reproduction-cost reproductive-cost * (body-size ^ metabolic-allometric-exponent)

    ; STATS AND VISUALIZATION
    set lineage-identity who
    set color scale-color yellow energy 0 (body-size)
    set size (body-size / 100)

    set standardized-ear energy-after-reprod / (body-size)
    set standardized-etr energy-to-reproduce / (body-size)
  ]

end


to generate-map
  set patch-palette [green brown orange blue red magenta violet lime yellow]
  let i 1
  while [i <= num-of-patch-types]
  [
    ask n-of num-of-seeds-per-type patches with [pcolor = 0]
    [
      set pcolor item (i - 1) patch-palette
      set base-color pcolor
      set resource-type (i - 1)
    ]
    set i (i + 1)
  ]

  while [any? patches with [pcolor = 0]]
  [
    ask patches with [pcolor = 0]
    [
      let n neighbors with [pcolor != 0]
      if any? n
      [
        let rand-patch one-of n
        set pcolor [pcolor] of rand-patch
        set base-color pcolor
        set resource-type [resource-type] of rand-patch
      ]
    ]
  ]
end

to go
  ifelse big-move-first?
  [agents-go-bigger-first]
  [agents-go-random]

  update-patch-resources

  update-perturbations

  tick
end

to update-patch-resources
  ask patches [
    regen-resources
    if patch-color-scales-with-resources? [
      set pcolor scale-color base-color resources -10 (max-resources * 2)
    ]
  ]
end

to update-perturbations
  if direct-event?
  [
    if random-float 1 < direct-event-frequency
    [
      let patches-altered 0
      let max-patches-altered ceiling (direct-event-coverage * count patches)
      ask n-of ceiling (max-patches-altered - (max-patches-altered * direct-event-clustering) + 1) patches
      [
        set under-d-perturbation? true
        set patches-altered patches-altered + 1

        if patches-altered > max-patches-altered
        [stop]
      ]
      while [patches-altered < max-patches-altered] [
        carefully [
          ask one-of patches with [under-d-perturbation? = true]
          [
            ask one-of neighbors with [under-d-perturbation? = false] [
              set under-d-perturbation? true
              set patches-altered patches-altered + 1

            ]
          ]
        ]
        [
        ]
      ]
      ask patches with [under-d-perturbation? = true] [
        ask turtles-here [
          if random-float 1 < direct-event-amplitude [
            die
          ]
        ]
        set under-d-perturbation? false
        set pcolor base-color
      ]
    ]
  ]
  if indirect-event?
  [
    ifelse random-float 1 < indirect-event-frequency
    [
      ifelse ongoing-indirect-perturbation?
      []
      ;else
      [
        set ongoing-indirect-perturbation? true
        let patches-altered 0
        let max-patches-altered ceiling (indirect-event-coverage * count patches)
        ask n-of ceiling (max-patches-altered - (max-patches-altered * indirect-event-clustering) + 1) patches
        [
          ;set pcolor scale-color item resource-type patch-palette indirect-event-amplitude 1 -1
          set pcolor brown
          set max-resources (max-resources - max-resources * indirect-event-amplitude)
          set resources (resources - resources * indirect-event-amplitude)
          set resource-regen (resource-regen - resource-regen * indirect-event-amplitude)

          set under-i-perturbation? true

          set patches-altered patches-altered + 1
          if patches-altered > max-patches-altered
          [stop]
        ]
        while [patches-altered < max-patches-altered] [
          carefully [
            ask one-of patches with [under-i-perturbation? = true]
            [
              ask one-of neighbors with [under-i-perturbation? = false] [
                ;set pcolor scale-color item resource-type patch-palette indirect-event-amplitude 1 -1
                set pcolor brown
                set max-resources (max-resources - max-resources * indirect-event-amplitude)
                set resources (resources - resources * indirect-event-amplitude)
                set resource-regen (resource-regen - resource-regen * indirect-event-amplitude)

                set under-i-perturbation? true

                set patches-altered patches-altered + 1
              ]
            ]
          ]
          [
          ]
        ]
      ]
    ]
    ;else
    [
      if ongoing-indirect-perturbation? = true
      [
        ask patches with [under-i-perturbation? = true]
        [
          set pcolor item resource-type patch-palette
          set max-resources original-max-resources
          set resources original-resources
          set resource-regen original-resource-regen
          set under-i-perturbation? false

          set ongoing-indirect-perturbation? false
        ]
      ]
    ]
  ]
end

to regen-resources

  set resources resources + resource-regen

  if resources > max-resources
  [
    set resources max-resources
  ]
end

to agents-go-bigger-first
  ;foreach sort-on [-1 * body-size + random-float 1 + random-float -1] turtles
  foreach sort-on [-1 * random-normal body-size (body-size * stand-dev-to-body-size)] turtles
  [ the-turtle -> ask the-turtle [
    agents-go
    ]
  ]
end

to agents-go-random
  ask turtles [
    agents-go
  ]
end

to agents-go
  ;if agents don't have enough energy to cover losses they die
  ifelse random-walk?
  [ disperse]
  ;else
  [
    ifelse forage?
    [forage]
    ;else
    [
      let energy-income get-energy-income patch-here
      let mean-energy-incomes get-mean-energy-incomes
      if (energy-income = 0) or (energy-income < mean-energy-incomes) [
        disperse
      ]
    ]
  ]
  if energy < 0 [die]

  if energy < body-size [
    eat
  ]
  ifelse age > maturity-age
  [
    if energy > energy-to-reproduce [
      ;if ticks-since-last-reproduction > interbirth-interval
      ;[
      reproduce
      set realized-interbirth-interval ticks-since-last-reproduction
      set ticks-since-last-reproduction -1 ; -1 because below we add +1
      ;]
      ]
  ]
  ;else
  [
    set energy energy - basal-growth-cost-per-tick
  ]
  set energy energy - basal-homeostasis-cost-per-tick
  set ticks-since-last-reproduction ticks-since-last-reproduction + 1
  set age age + 1

  ; die of old age
  if random age > longevity [die]
  if energy < 0 [die]
  set color scale-color yellow energy 0 (body-size)
end

to eat
  ; Eats whatever is under the agent.
  ;
  let energy-income 0
  ask patch-here [
    ifelse resources > [basal-resource-intake] of myself
    [
      ;multiply basal-resource intake by the habitat spec value
      set energy-income [basal-resource-intake] of myself *
      item resource-type [habitat-spec] of myself
      ;set resources resources - [basal-resource-intake] of myself
      set resources resources - energy-income

    ]
    [
      set energy-income ([basal-resource-intake] of myself +
      (resources - [basal-resource-intake] of myself) ) *
      item resource-type [habitat-spec] of myself
      set resources 0
    ]
  ]
  set energy energy + energy-income
end

to-report get-mean-energy-incomes
  ;UGLY FUNCTION
  ;calculate the energy income of a patch
  let mean-energy-income 0
  let num-patches 0
  ask patches in-radius disp-ability [
    ifelse resources > [basal-resource-intake] of myself
    [
      ;multiply basal-resource intake by the habitat spec value
      set mean-energy-income mean-energy-income + [basal-resource-intake] of myself *
      item resource-type [habitat-spec] of myself
      set num-patches num-patches + 1

    ]
    [
      set mean-energy-income mean-energy-income + ([basal-resource-intake] of myself +
      (resources - [basal-resource-intake] of myself) ) *
      item resource-type [habitat-spec] of myself
      set num-patches num-patches + 1
    ]
  ]
  set mean-energy-income mean-energy-income / num-patches
  report mean-energy-income
end

to-report get-energy-income [ptch]
  ;get energy income if agent eats in current patch
  let energy-income 0
  ask ptch [
    ifelse resources > [basal-resource-intake] of myself
    [
      ;multiply basal-resource intake by the habitat spec value
      set energy-income [basal-resource-intake] of myself *
      item resource-type [habitat-spec] of myself
    ]
    [
      set energy-income ([basal-resource-intake] of myself +
      (resources - [basal-resource-intake] of myself) ) *
      item resource-type [habitat-spec] of myself
    ]
  ]
  report energy-income
end


to disperse
  ifelse (age < maturity-age and item 0 disp-stage = 0) or (age > maturity-age and item 1 disp-stage = 0)
  [
    ;do nothing if this stage is non-disperser
  ]
  [
    let disp-distance random disp-ability
    set heading random 360
    fd disp-distance
    set energy energy - (basal-dispersal-cost-per-unit * disp-distance)
  ]
end

to reproduce
  let energy_to_offspring energy - energy-after-reprod - reproduction-cost
  let parent-body-size body-size
  set energy energy-after-reprod
  set realized-maturity-age age

  repeat fecundity
  [
    hatch 1 [
      set energy (energy_to_offspring / [fecundity] of myself)
      set age 0
      set body-size random-normal [body-size] of myself ([body-size] of myself * mutation-size-body-size)
      if body-size < 0 [set body-size 0.1]
      set interbirth-interval random-normal [interbirth-interval] of myself ([interbirth-interval] of myself * mutation-size-interbirth-interval)
      set fecundity  random-normal [fecundity] of myself ([fecundity] of myself * mutation-size-fecundity)
      if fecundity < 1 [set fecundity 1]
      set maturity-age random-normal [maturity-age] of myself ([maturity-age] of myself * mutation-size-maturity-age)
      set longevity maturity-longevity-coefficient * maturity-age
      set habitat-spec mutate-habitat-spec [habitat-spec] of myself
      ;set sexual?
      set disp-ability random-normal [disp-ability] of myself ([disp-ability] of myself * mutation-size-dispersal-ability)
      ;set disp-stage
      ;set climate-optimum
      ;set climate-sd

      ; * BODY-SIZE ^ allometric-constant TRAITS
      set basal-dispersal-cost-per-unit starting-basal-dispersal-cost-per-unit * (body-size ^ metabolic-allometric-exponent)
      set basal-growth-cost-per-tick starting-basal-growth-cost-per-tick * (body-size ^ metabolic-allometric-exponent)
      set basal-homeostasis-cost-per-tick starting-basal-homeostasis-cost-per-tick * (body-size ^ metabolic-allometric-exponent)
      set basal-resource-intake starting-basal-resource-intake * (body-size ^ metabolic-allometric-exponent)

      ; BODY-SIZE SCALING TRAITS (but not allometrically
      set energy-to-reproduce random-normal [energy-to-reproduce] of myself ([energy-to-reproduce] of myself * mutation-size-etr)
      set energy-after-reprod random-normal [energy-after-reprod] of myself ([energy-after-reprod] of myself * mutation-size-ear)

      set ticks-since-last-reproduction 0 ; high value so that organisms automatically reproduce when they can the first time ; now it~s low value
      set reproduction-cost reproductive-cost * (body-size ^ metabolic-allometric-exponent)

      ; STATS AND VISUALIZATION
      set lineage-identity who

      set standardized-etr energy-to-reproduce / (body-size )
      set standardized-ear energy-after-reprod / (body-size)

      set color scale-color yellow energy 0 (body-size)
      set size (body-size / 100)

    ]
  ]
end

to-report calc-random-gamma-from-mean-and-sv [mean_ sd]
  if mean_ < 0.00000001
  [  set mean_ 0.00000001 ]

  let alpha mean_ * mean_ / sd
  let lambda 1 / (sd / mean_)

  report random-gamma alpha lambda
end

to-report calc-random-normal-with-abs [mean_ sd]
  report abs random-normal mean_ sd
end

to-report mutate-habitat-spec [hab-spec]
  let new-habitat-spec [0 0 0 0]
  let total-sum-of-random 0
  let i 0
  while [i < num-of-patch-types]
  [
    let new-random 0
    ifelse gamma?
    [set new-random calc-random-gamma-from-mean-and-sv item i hab-spec mutation-size-habitat-spec]
    [set new-random calc-random-normal-with-abs item i hab-spec mutation-size-habitat-spec]

    set new-habitat-spec replace-item i new-habitat-spec new-random
    set total-sum-of-random total-sum-of-random + new-random
    set i i + 1
  ]
  set i 0
  while [i < num-of-patch-types]
  [
    set new-habitat-spec replace-item i new-habitat-spec  ( item i new-habitat-spec / total-sum-of-random )
    set i i + 1
  ]

  report new-habitat-spec
end


to reset-patch-colors
  ask patches
  [
    set pcolor base-color
  ]
end

to forage ;forage by going to the best cell available, or just disperse when all cells around have no resources
  let p max-one-of patches in-radius disp-ability [resources]
  let potential-income-of-this-patch  get-energy-income patch-here
  let potential-income-of-new-patch get-energy-income p

  let potential-dispersal-distance distance p
  let potential-dispersal-cost potential-dispersal-distance * basal-dispersal-cost-per-unit

  ifelse potential-income-of-this-patch = 0  and potential-income-of-new-patch = 0 ;move even if it hurts energy if there is no possible outcome in the cells around
    [
      disperse
  ]
  ;else
  [
    if potential-income-of-new-patch - potential-dispersal-cost > potential-income-of-this-patch and energy > potential-dispersal-cost [
      face p
      move-to p
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
599
184
1102
688
-1
-1
15.0
1
10
1
1
1
0
1
1
1
-16
16
-16
16
1
1
1
ticks
30.0

TEXTBOX
2273
38
2423
56
Map generator
11
0.0
1

SLIDER
2268
61
2440
94
num-of-patch-types
num-of-patch-types
1
4
2.0
1
1
NIL
HORIZONTAL

SLIDER
2266
97
2445
130
num-of-seeds-per-type
num-of-seeds-per-type
1
(world-width * world-height) / num-of-patch-types
1.0
10
1
NIL
HORIZONTAL

BUTTON
1106
487
1169
520
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

BUTTON
1105
521
1168
554
go
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

BUTTON
1105
554
1168
587
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

MONITOR
1411
239
1494
284
NIL
count turtles
17
1
11

PLOT
383
172
584
321
mean body-size
NIL
NIL
0.0
10.0
30.0
50.0
true
false
"" ""
PENS
"mean" 1.0 0 -16777216 true "let mean-bs mean [body-size] of turtles" "plot mean [body-size] of turtles"

PLOT
399
626
597
776
mean fecundity
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
"default" 1.0 0 -16777216 true "" "plot mean [fecundity] of turtles"
"pen-1" 1.0 0 -7500403 true "" "plot median [fecundity] of turtles"

MONITOR
1406
191
1508
236
green patches
count patches with [pcolor = green]
17
1
11

PLOT
179
172
379
322
Number of organisms
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
"default" 1.0 0 -16777216 true "" "plot count turtles"

PLOT
-4
626
196
776
mean maturity-age
NIL
NIL
0.0
10.0
20.0
40.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [maturity-age] of turtles"

PLOT
198
626
398
776
mean dispersal ability
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
"default" 1.0 0 -16777216 true "" "plot mean [disp-ability] of turtles"

PLOT
1121
182
1321
332
mean age
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
"mean" 1.0 0 -16777216 true "" "plot mean [age] of turtles"

SWITCH
1746
304
1994
337
patch-color-scales-with-resources?
patch-color-scales-with-resources?
1
1
-1000

SWITCH
1745
72
1877
105
big-move-first?
big-move-first?
0
1
-1000

SWITCH
1848
267
1980
300
random-walk?
random-walk?
1
1
-1000

BUTTON
1581
330
1681
363
reset patch colors
reset-patch-colors
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
2268
388
2440
421
mutation-size
mutation-size
0
0.5
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
1745
137
1958
170
maturity-longevity-coefficient
maturity-longevity-coefficient
1
10
4.0
0.1
1
NIL
HORIZONTAL

SLIDER
1745
234
1923
267
reproductive-cost
reproductive-cost
0
1
0.1
0.01
1
NIL
HORIZONTAL

SLIDER
2267
421
2447
454
mutation-size-fecundity
mutation-size-fecundity
0
5
0.0
0.01
1
NIL
HORIZONTAL

PLOT
179
474
379
624
mean energy
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
"default" 1.0 0 -16777216 true "" "plot mean [energy] of turtles"
"pen-1" 1.0 0 -7500403 true "" "plot min [energy] of turtles"

PLOT
179
323
379
473
total resources
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
"default" 1.0 0 -16777216 true "" "plot sum [resources] of patches"

PLOT
383
322
583
472
body-size histogram
NIL
NIL
0.0
200.0
0.0
10.0
true
false
"set-plot-pen-mode 1\nset-plot-pen-interval 1" ""
PENS
"default" 1.0 0 -16777216 true "" "histogram [body-size] of turtles"

TEXTBOX
1389
28
1539
46
indirect event
11
0.0
1

TEXTBOX
1573
27
1723
45
direct event
11
0.0
1

SLIDER
1542
46
1721
79
direct-event-frequency
direct-event-frequency
0
1
1.0
0.01
1
NIL
HORIZONTAL

SWITCH
1104
437
1228
470
direct-event?
direct-event?
1
1
-1000

SLIDER
1542
79
1717
112
direct-event-amplitude
direct-event-amplitude
0.01
1
0.03
0.01
1
NIL
HORIZONTAL

SWITCH
1104
405
1228
438
indirect-event?
indirect-event?
1
1
-1000

SLIDER
1348
47
1536
80
indirect-event-frequency
indirect-event-frequency
0
1
1.0
0.01
1
NIL
HORIZONTAL

SLIDER
1349
80
1534
113
indirect-event-amplitude
indirect-event-amplitude
0.01
1
1.0
0.01
1
NIL
HORIZONTAL

SLIDER
1348
116
1532
149
indirect-event-coverage
indirect-event-coverage
0
1
0.7
0.01
1
NIL
HORIZONTAL

SLIDER
1543
110
1717
143
direct-event-coverage
direct-event-coverage
0
1
1.0
0.01
1
NIL
HORIZONTAL

SLIDER
1543
143
1718
176
direct-event-clustering
direct-event-clustering
0
1
0.01
0.01
1
NIL
HORIZONTAL

SLIDER
1348
147
1533
180
indirect-event-clustering
indirect-event-clustering
0.000
1
0.088
0.001
1
NIL
HORIZONTAL

PLOT
1288
463
1563
613
age at first reproduction
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
"default" 1.0 0 -16777216 true "" "plot mean [realized-maturity-age] of turtles"

PLOT
1288
312
1564
462
interbirth interval
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
"default" 1.0 0 -16777216 true "" "plot mean [realized-interbirth-interval] of turtles"

INPUTBOX
1975
440
2065
500
starting-body-size
30.0
1
0
Number

INPUTBOX
2068
441
2195
501
starting-interbirth-interval
10.0
1
0
Number

INPUTBOX
1878
440
1973
500
starting-fecundity
1.0
1
0
Number

INPUTBOX
1758
440
1874
500
starting-maturity-age
40.0
1
0
Number

INPUTBOX
1860
379
1987
439
starting-habitat-spec
1,0,0,0
1
1
String

INPUTBOX
1990
379
2089
439
starting-disp-ability
1.2
1
0
Number

INPUTBOX
1758
379
1858
439
starting-disp-stage
1,1
1
0
String

SWITCH
1758
501
1902
534
starting-sexual?
starting-sexual?
1
1
-1000

INPUTBOX
2008
587
2095
647
starting-energy
0.2
1
0
Number

INPUTBOX
2008
526
2163
586
starting-age
5.0
1
0
Number

INPUTBOX
1761
617
1860
677
starting-basal-dispersal-cost-per-unit
0.01
1
0
Number

INPUTBOX
1761
678
1874
738
starting-basal-growth-cost-per-tick
0.02
1
0
Number

INPUTBOX
1761
557
1895
617
starting-basal-homeostasis-cost-per-tick
0.02
1
0
Number

INPUTBOX
1761
739
1881
799
starting-basal-resource-intake
0.1
1
0
Number

INPUTBOX
2008
659
2172
719
starting-ratio-energy-to-reproduce
0.67
1
0
Number

INPUTBOX
2008
719
2163
779
starting-ratio-energy-after-reprod
0.33
1
0
Number

INPUTBOX
1878
73
1961
133
starting-no
1000.0
1
0
Number

INPUTBOX
2139
62
2255
122
starting-resources
2.0
1
0
Number

INPUTBOX
2139
122
2256
182
starting-max-resources
4.0
1
0
Number

INPUTBOX
2138
183
2256
243
starting-resource-regen
2.0
1
0
Number

INPUTBOX
1965
70
2043
130
min-xcor
-16.0
1
0
Number

INPUTBOX
2044
70
2123
130
max-xcor
16.0
1
0
Number

INPUTBOX
1965
131
2043
191
min-ycor
-16.0
1
0
Number

INPUTBOX
2044
131
2122
191
max-ycor
16.0
1
0
Number

INPUTBOX
1965
191
2043
251
patch-n-pixels
15.0
1
0
Number

INPUTBOX
1745
172
1849
232
metabolic-allometric-exponent
0.75
1
0
Number

INPUTBOX
1850
172
1954
232
stand-dev-to-body-size
1.0
1
0
Number

TEXTBOX
1757
49
1907
67
world
11
0.0
1

TEXTBOX
1971
53
2121
71
world dimensions
11
0.0
1

TEXTBOX
2147
42
2245
60
Patches
11
0.0
1

TEXTBOX
1766
347
1916
365
ORGANISM TRAITS\t\n
11
0.0
1

TEXTBOX
1767
363
1917
381
focal traits
11
0.0
1

TEXTBOX
2026
510
2176
528
starting age and energy
11
0.0
1

TEXTBOX
1763
540
1931
568
energy expenditure and uptake
11
0.0
1

SLIDER
2273
165
2459
198
mutation-size-body-size
mutation-size-body-size
0
1
0.05
0.01
1
NIL
HORIZONTAL

SLIDER
2273
197
2459
230
mutation-size-dispersal-ability
mutation-size-dispersal-ability
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
2271
229
2469
262
mutation-size-interbirth-interval
mutation-size-interbirth-interval
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
2270
261
2470
294
mutation-size-maturity-age
mutation-size-maturity-age
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
2271
359
2468
392
mutation-size-habitat-spec
mutation-size-habitat-spec
0
1
0.0
0.01
1
NIL
HORIZONTAL

PLOT
804
692
1004
842
specialization for resource type 1
NIL
NIL
0.0
1.01
0.0
10.0
true
false
"set-plot-pen-mode 1\nset-plot-pen-interval 0.01" ""
PENS
"default" 1.0 0 -16777216 true "" "histogram [item 0 habitat-spec] of turtles"

SWITCH
2267
454
2370
487
gamma?
gamma?
1
1
-1000

SLIDER
2270
294
2442
327
mutation-size-ear
mutation-size-ear
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
2270
327
2442
360
mutation-size-etr
mutation-size-etr
0
1
0.0
0.01
1
NIL
HORIZONTAL

PLOT
602
692
802
842
ear
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [standardized-ear] of turtles"

PLOT
399
777
599
927
etr
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [standardized-etr] of turtles"

PLOT
383
471
583
621
total energy
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
"default" 1.0 0 -16777216 true "" "plot sum [energy] of turtles"

PLOT
1117
698
1317
848
histogram of energy
NIL
NIL
-5.0
70.0
0.0
10.0
true
false
"set-plot-pen-mode 1\nset-plot-pen-interval 0.1" ""
PENS
"default" 1.0 0 -16777216 true "" "histogram [energy] of turtles"

SWITCH
1746
267
1849
300
forage?
forage?
1
1
-1000

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

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
  <experiment name="local_optima" repetitions="20" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50000"/>
    <exitCondition>count turtles = 0</exitCondition>
    <metric>count turtles</metric>
    <metric>count [resources] of patches</metric>
    <metric>sum [energy] of turtles</metric>
    <metric>mean [energy] of turtles</metric>
    <metric>mean [maturity-age] of turtles</metric>
    <metric>mean [disp-ability] of turtles</metric>
    <metric>mean [fecundity] of turtles</metric>
    <metric>mean [standardized-ear] of turtles</metric>
    <metric>mean [standardized-etr] of turtles</metric>
    <enumeratedValueSet variable="indirect-event?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="patch-n-pixels">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gamma?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="random-walk?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stand-dev-to-body-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-age">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-ycor">
      <value value="-16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="metabolic-allometric-exponent">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="direct-event-clustering">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-xcor">
      <value value="-16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-disp-ability">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-basal-growth-cost-per-tick">
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutation-size-ear">
      <value value="0"/>
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maturity-longevity-coefficient">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="indirect-event-amplitude">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="forage?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-of-patch-types">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-no">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="direct-event?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-basal-homeostasis-cost-per-tick">
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="indirect-event-clustering">
      <value value="0.088"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-resource-regen">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-disp-stage">
      <value value="&quot;1,1&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-of-seeds-per-type">
      <value value="1"/>
      <value value="50"/>
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-basal-resource-intake">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutation-size-habitat-spec">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-sexual?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="patch-color-scales-with-resources?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-ratio-energy-after-reprod">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-habitat-spec">
      <value value="&quot;1,0,0,0&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-energy">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-interbirth-interval">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="direct-event-coverage">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="direct-event-amplitude">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-ratio-energy-to-reproduce">
      <value value="0.67"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-basal-dispersal-cost-per-unit">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-body-size">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-maturity-age">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-fecundity">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reproductive-cost">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ycor">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutation-size">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="big-move-first?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="direct-event-frequency">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-xcor">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="indirect-event-frequency">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutation-size-etr">
      <value value="0"/>
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="indirect-event-coverage">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-max-resources">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutation-size-dispersal-ability">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-resources">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutation-size-body-size">
      <value value="0"/>
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutation-size-fecundity">
      <value value="0"/>
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutation-size-interbirth-interval">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutation-size-maturity-age">
      <value value="0"/>
      <value value="0.05"/>
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
