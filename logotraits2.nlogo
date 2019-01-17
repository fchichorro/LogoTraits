extensions[ csv ]

globals[
  ; LANDSCAPE GENERATION
  ; num-of-seeds-per-type
  ; num-of-patch-types
    patch-palette                  ; the colours of the patches

  ; PATCHES
  ; PATCHES PARAMETERS
  ;
  starting-resources-min
  starting-resources-max
  resource-regen-min
  resource-regen-max
  max-resources-min
  max-resources-max

  ; ORGANISMS
  ; POPULATION LEVEL PARAMETERS
  n1
  males-per-female

  ; FOCAL TRAITS
  body-size-max
  body-size-min
  interbirth-interval-max
  interbirth-interval-min
  fecundity-max
  fecundity-min
  maturity-age-max
  maturity-age-min
  longevity-max
  longevity-min
  habitat-spec-max
  habitat-spec-min
  sexual?-max
  sexual?-min
  disp-ability-max
  disp-ability-min
  disp-stage-max
  disp-stage-min
  climate-optimum-max
  climate-optimum-min
  climate-sd-max
  climate-sd-min

  ; NON-FOCAL TRAITS
  starting-energy-max
  starting-energy-min
  starting-age-max
  starting-age-min
  basal-dispersal-cost-per-unit-max
  basal-dispersal-cost-per-unit-min
  basal-growth-cost-per-tick-max
  basal-growth-cost-per-tick-min
  basal-homeostasis-cost-per-tick-max
  basal-homeostasis-cost-per-tick-min
  basal-resource-intake-max
  basal-resource-intake-min
  ratio-energy-to-reproduce-min
  ratio-energy-to-reproduce-max
  ratio-min-energy-after-reprod-min
  ratio-min-energy-after-reprod-max

  ; WORLD CONSTANTS
  metabolic-allometric-exponent
  stand-dev-to-body-size

  ; in test
  ;mortality-rate

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
  climate-optimum
  climate-sd

  ; NON-FOCAL TRAITS
  energy
  age
  basal-dispersal-cost-per-unit
  basal-growth-cost-per-tick
  basal-homeostasis-cost-per-tick
  basal-resource-intake
  energy-to-reproduce
  min-energy-after-reprod
  ticks-since-last-reproduction
  reproduction-cost

  ;stats
  lineage-identity

]

patches-own[
  resource-type
  resources
  max-resources
  resource-regen

  ; visualization
  base-color
]

breed [organisms1 organism1]
breed [organisms2 organism2]

; Import world parameters
to set-world-parameters
  file-open "world_settings.txt"
  repeat 2 [ show file-read-line ]
  let min-xcor read-from-string file-read-line
  show file-read-line
  let max-xcor read-from-string file-read-line
  show file-read-line
  let min-ycor read-from-string file-read-line
  show file-read-line
  let max-ycor read-from-string file-read-line
  show file-read-line
  set-patch-size (read-from-string file-read-line)
  resize-world min-xcor max-xcor min-ycor max-ycor
  repeat 3 [ show file-read-line ]

  ; METABOLIC THEORY CONSTANTS
  show file-read-line
  set metabolic-allometric-exponent (read-from-string file-read-line)
  show file-read-line
  set stand-dev-to-body-size (read-from-string file-read-line)
  file-close

end



; Import from files
to import-organism-parameters [ filename ]
  file-open filename

  ; POPULATION LEVEL PARAMETERS
  repeat 2 [ show file-read-line ]
  set n1 read-from-string file-read-line
  show file-read-line
  set males-per-female read-from-string file-read-line
  repeat 3 [ show file-read-line ]

  ; FOCAL TRAITS
  show file-read-line
  set body-size-min read-from-string file-read-line
  set body-size-max read-from-string file-read-line
  show file-read-line
  set interbirth-interval-min read-from-string file-read-line
  set interbirth-interval-max read-from-string file-read-line
  show file-read-line
  set fecundity-min read-from-string file-read-line
  set fecundity-max read-from-string file-read-line
  show file-read-line
  set maturity-age-min read-from-string file-read-line
  set maturity-age-max read-from-string file-read-line
  show file-read-line
  set longevity-min read-from-string file-read-line
  set longevity-max read-from-string file-read-line
  show file-read-line
  set habitat-spec-min csv:from-row file-read-line
  set habitat-spec-max csv:from-row file-read-line
  show file-read-line
  set sexual?-min read-from-string file-read-line
  set sexual?-max read-from-string file-read-line
  show file-read-line
  set disp-ability-min read-from-string file-read-line
  set disp-ability-max read-from-string file-read-line
  show file-read-line
  set disp-stage-min csv:from-row file-read-line
  set disp-stage-max csv:from-row file-read-line
  show file-read-line
  set climate-optimum-min read-from-string file-read-line
  set climate-optimum-max read-from-string file-read-line
  show file-read-line
  set climate-sd-min read-from-string file-read-line
  set climate-sd-max read-from-string file-read-line
  repeat 3 [ show file-read-line ]

  ; NON-FOCAL TRAITS
  show file-read-line
  set starting-energy-min read-from-string file-read-line
  set starting-energy-max read-from-string file-read-line
  show file-read-line
  set starting-age-min read-from-string file-read-line
  set starting-age-max read-from-string file-read-line
  show file-read-line
  set basal-dispersal-cost-per-unit-min read-from-string file-read-line
  set basal-dispersal-cost-per-unit-max read-from-string file-read-line
  show file-read-line
  set basal-growth-cost-per-tick-min read-from-string file-read-line
  set basal-growth-cost-per-tick-max read-from-string file-read-line
  show file-read-line
  set basal-homeostasis-cost-per-tick-min read-from-string file-read-line
  set basal-homeostasis-cost-per-tick-max read-from-string file-read-line
  show file-read-line
  set basal-resource-intake-min read-from-string file-read-line
  set basal-resource-intake-max read-from-string file-read-line
  show file-read-line
  set ratio-energy-to-reproduce-min read-from-string file-read-line
  set ratio-energy-to-reproduce-max read-from-string file-read-line
  show file-read-line
  set ratio-min-energy-after-reprod-min read-from-string file-read-line
  set ratio-min-energy-after-reprod-max read-from-string file-read-line

  file-close
end

; Import from files
to import-patch-parameters
  file-open "patches.txt"
  repeat 2 [ show file-read-line ]
  set starting-resources-min read-from-string file-read-line
  set starting-resources-max read-from-string file-read-line
  show file-read-line
  set max-resources-min read-from-string file-read-line
  set max-resources-max read-from-string file-read-line
  show file-read-line
  set resource-regen-min read-from-string file-read-line
  set resource-regen-max read-from-string file-read-line
  file-close
end


to setup
  clear-all
  reset-ticks
  set-world-parameters
  generate-landscape-of-patch-types
  import-patch-parameters
  ;initialize patches
  ask patches [
    set resources one-of (range starting-resources-min ( starting-resources-max + 1 ))
    set max-resources one-of (range max-resources-min ( max-resources-max + 1 ))
    set resource-regen one-of (range resource-regen-min (resource-regen-max + resource-regen-step) resource-regen-step)
  ]


  import-organism-parameters "organism1.txt"
  ;create organisms1
  create-organisms1 n1
  [

    ; FOCAL TRAITS
    set body-size one-of (range body-size-min ( body-size-max + 1 ))
    set interbirth-interval one-of ( range interbirth-interval-min ( interbirth-interval-max + 1 ))
    set fecundity one-of (range fecundity-min ( fecundity-max + 1 ))
    set maturity-age one-of (range maturity-age-min ( maturity-age-max + 1 ))
    set longevity maturity-longevity-coefficient * maturity-age
    set habitat-spec one-of list habitat-spec-min habitat-spec-max
    set sexual? one-of list sexual?-min sexual?-max
    set disp-ability one-of (range disp-ability-min ( disp-ability-max + 1 ))
    set disp-stage one-of list disp-stage-min disp-stage-max
    set climate-optimum one-of (range (climate-optimum-min * 100) (climate-optimum-max  * 100 + 1) ) / 100
    set climate-sd one-of (range (climate-sd-min * 100) (climate-sd-max  * 100 + 1) ) / 100

    ; INITIAL ENERGY AND AGE AND SPATIAL CORDINATES
    set xcor random-xcor
    set ycor random-ycor
    set energy one-of (range starting-energy-min ( starting-energy-max + 1 )) * (body-size ^ metabolic-allometric-exponent)
    set age one-of (range starting-age-min (starting-age-max + 1 ))

    ; * BODY-SIZE ^ allometric-constant TRAITS
    set basal-dispersal-cost-per-unit one-of (range basal-dispersal-cost-per-unit-min ( basal-dispersal-cost-per-unit-max + 1 )) * (body-size ^ metabolic-allometric-exponent)
    set basal-growth-cost-per-tick one-of (range basal-growth-cost-per-tick-min ( basal-growth-cost-per-tick-max + 1 )) * (body-size ^ metabolic-allometric-exponent)
    set basal-homeostasis-cost-per-tick one-of (range  basal-homeostasis-cost-per-tick-min ( basal-homeostasis-cost-per-tick-max + 1 )) * (body-size ^ metabolic-allometric-exponent)
    set basal-resource-intake one-of (range basal-resource-intake-min ( basal-resource-intake-max + 1 )) * (body-size ^ metabolic-allometric-exponent)

    ; BODY-SIZE SCALING TRAITS (but not allometrically
    set energy-to-reproduce one-of (range ratio-energy-to-reproduce-min ( ratio-energy-to-reproduce-max + 1 )) * (body-size ^ metabolic-allometric-exponent)
    set min-energy-after-reprod one-of (range ratio-min-energy-after-reprod-min ( ratio-min-energy-after-reprod-max + 1 )) * (body-size ^ metabolic-allometric-exponent)
    set ticks-since-last-reproduction 0 ; high value so that organisms automatically reproduce when they can the first time ; now it~s low value
    set reproduction-cost reproductive-cost * (body-size ^ metabolic-allometric-exponent)

    ; STATS AND VISUALIZATION
    set lineage-identity who
    set size (body-size / 300)
  ]

end


to generate-landscape-of-patch-types
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

  patches-go

  tick
end

to patches-go
  ask patches [
    regen-resources
    if patch-color-scales-with-resources? [
      set pcolor scale-color base-color resources -10 (max-resources * 2)
    ]
  ]
end


to regen-resources
  if resources < max-resources
  [
    set resource-regen one-of (range resource-regen-min (resource-regen-max + resource-regen-step) resource-regen-step)
    set resources resources + resource-regen
  ]
end

to agents-go-bigger-first
  ;foreach sort-on [-1 * body-size + random-float 1 + random-float -1] turtles
  foreach sort-on [-1 * random-normal body-size (((body-size-min + body-size-max) / 2) * stand-dev-to-body-size)] turtles
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
  ifelse random-walk?
  [ disperse]
  [let energy-income get-energy-income
    let mean-energy-incomes get-mean-energy-incomes
    if (energy-income = 0) or (energy-income < mean-energy-incomes) [
      disperse
    ]
  ]
  if energy < body-size [
    eat
  ]
  ifelse age > maturity-age
  [
    if energy > energy-to-reproduce [
      if ticks-since-last-reproduction > interbirth-interval
      [
      reproduce
      set ticks-since-last-reproduction -1 ; -1 because below we add +1
      ]
      ]
  ]
  ;else
  [
    set energy energy - basal-growth-cost-per-tick
  ]

  set ticks-since-last-reproduction ticks-since-last-reproduction + 1
  set age age + 1
  set energy energy - basal-homeostasis-cost-per-tick
  if energy < 0 [die]
  ; in test
  if random-float 1 < mortality-rate [die]
  ; die of old age
  if random age > longevity [die]
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
      set resources resources - [basal-resource-intake] of myself

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
  ask [patches in-radius resource-perception-radius] of patch-here [
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

to-report get-energy-income
  ;get energy income if agent eats in current patch
  let energy-income 0
  ask patch-here [
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

to eat-or-move
  ; Eats whatever is under the agent.
  ;
  let energy-income 0
  ask patch-here [
    ifelse resources > [basal-resource-intake] of myself
    [
      ;multiply basal-resource intake by the habitat spec value
      set energy-income [basal-resource-intake] of myself *
      item resource-type [habitat-spec] of myself
      set resources resources - [basal-resource-intake] of myself

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
  let energy_to_offspring energy - min-energy-after-reprod - reproductive-cost
  let parent-body-size body-size
  set energy min-energy-after-reprod
  repeat fecundity
  [
    hatch 1 [
      set energy (energy_to_offspring / [fecundity] of myself)
      set age 0
      set body-size random-normal [body-size] of myself ([body-size] of myself * mutation-size)
      set interbirth-interval random-normal [interbirth-interval] of myself ([interbirth-interval] of myself * mutation-size)
      set fecundity  random-poisson [fecundity] of myself
      if fecundity < 1 [set fecundity 1]
      set maturity-age random-normal [maturity-age] of myself ([maturity-age] of myself * mutation-size)
      set longevity maturity-longevity-coefficient * maturity-age
      ;set habitat-spec
      ;set sexual?
      set disp-ability random-normal [disp-ability] of myself ([disp-ability] of myself * mutation-size)
      ;set disp-stage
      ;set climate-optimum
      ;set climate-sd

      ; * BODY-SIZE ^ allometric-constant TRAITS
      set basal-dispersal-cost-per-unit one-of (range basal-dispersal-cost-per-unit-min ( basal-dispersal-cost-per-unit-max + 1 )) * (body-size ^ metabolic-allometric-exponent)
      set basal-growth-cost-per-tick one-of (range basal-growth-cost-per-tick-min ( basal-growth-cost-per-tick-max + 1 )) * (body-size ^ metabolic-allometric-exponent)
      set basal-homeostasis-cost-per-tick one-of (range  basal-homeostasis-cost-per-tick-min ( basal-homeostasis-cost-per-tick-max + 1 )) * (body-size ^ metabolic-allometric-exponent)
      set basal-resource-intake one-of (range basal-resource-intake-min ( basal-resource-intake-max + 1 )) * (body-size ^ metabolic-allometric-exponent)


      ; BODY-SIZE SCALING TRAITS (but not allometrically
      set energy-to-reproduce one-of (range ratio-energy-to-reproduce-min ( ratio-energy-to-reproduce-max + 1 )) * (body-size ^ metabolic-allometric-exponent)
      set min-energy-after-reprod one-of (range ratio-min-energy-after-reprod-min ( ratio-min-energy-after-reprod-max + 1 )) * (body-size ^ metabolic-allometric-exponent)
      set ticks-since-last-reproduction 0 ; high value so that organisms automatically reproduce when they can the first time ; now it~s low value
      set reproduction-cost reproductive-cost * (body-size ^ metabolic-allometric-exponent)

      ; STATS AND VISUALIZATION
      set lineage-identity who
      set size (body-size / 300)

    ]
  ]
end


to create-offspring



end


; THREATS

to degrade-habitat
  ask one-of patches with [pcolor != 0][
      set resources 0
      set max-resources 0
      set resource-regen 0
      set pcolor 0
    degrade-patch
  ]
end

to degrade-patch
  ask n-of 1 neighbors [
    ifelse pcolor != 0 [

      set resources 0
      set max-resources 0
      set resource-regen 0
      set pcolor 0
      degrade-patch
    ]
    [
      stop
    ]
  ]
end

to exterminate-habitat
  ask one-of patches [
    exterminate-patch hunter-steps
  ]
end

to exterminate-patch [steps-remaining]
  if steps-remaining > 0 [
    ask max-n-of 1 patch-set neighbors [sum [energy] of turtles-here][
      ifelse count turtles-here > 0
      [
        ;watch-me

        ask turtles-here
        [
          die
        ]

      ]
      ;else
      [
      ]
      set pcolor red
      set steps-remaining steps-remaining - 1
      exterminate-patch steps-remaining
    ]
  ]
end


to add-invasives
  let allien-color white
  let allien-body-size one-of (range body-size-min ( body-size-max + 1 ))
  let allien-interbirth-interval one-of ( range interbirth-interval-min ( interbirth-interval-max + 1 ))
  let allien-fecundity one-of (range fecundity-min ( fecundity-max + 1 ))
  let allien-maturity-age one-of (range maturity-age-min ( maturity-age-max + 1 ))
  let allien-longevity maturity-longevity-coefficient * allien-maturity-age
  let allien-habitat-spec one-of list habitat-spec-min habitat-spec-max
  let allien-sexual? one-of list sexual?-min sexual?-max
  let allien-disp-ability one-of (range disp-ability-min ( disp-ability-max + 1 ))
  let allien-disp-stage one-of list disp-stage-min disp-stage-max
  let allien-climate-optimum one-of (range (climate-optimum-min * 100) (climate-optimum-max  * 100 + 1) ) / 100
  let allien-climate-sd one-of (range (climate-sd-min * 100) (climate-sd-max  * 100 + 1) ) / 100

  ; INITIAL ENERGY AND AGE AND SPATIAL CORDINATES
  let allien-xcor random-xcor
  let allien-ycor random-ycor
  let allien-energy one-of (range starting-energy-min ( starting-energy-max + 1 )) * (allien-body-size ^ metabolic-allometric-exponent)
  let allien-age one-of (range starting-age-min (starting-age-max + 1 ))

  ; * BODY-SIZE ^ allometric-constant TRAITS
  let allien-basal-dispersal-cost-per-unit one-of (range basal-dispersal-cost-per-unit-min ( basal-dispersal-cost-per-unit-max + 1 )) * (allien-body-size ^ metabolic-allometric-exponent)
  let allien-basal-growth-cost-per-tick one-of (range basal-growth-cost-per-tick-min ( basal-growth-cost-per-tick-max + 1 )) * (allien-body-size ^ metabolic-allometric-exponent)
  let allien-basal-homeostasis-cost-per-tick one-of (range  basal-homeostasis-cost-per-tick-min ( basal-homeostasis-cost-per-tick-max + 1 )) * (allien-body-size ^ metabolic-allometric-exponent)
  let allien-basal-resource-intake one-of (range basal-resource-intake-min ( basal-resource-intake-max + 1 )) * (allien-body-size ^ metabolic-allometric-exponent)
 ; BODY-SIZE SCALING TRAITS (but not allometrically
  let allien-energy-to-reproduce one-of (range ratio-energy-to-reproduce-min ( ratio-energy-to-reproduce-max + 1 )) * (allien-body-size ^ metabolic-allometric-exponent)
  let allien-min-energy-after-reprod one-of (range ratio-min-energy-after-reprod-min ( ratio-min-energy-after-reprod-max + 1 )) * (allien-body-size ^ metabolic-allometric-exponent)
  let allien-ticks-since-last-reproduction 0 ; high value so that organisms automatically reproduce when they can the first time ; now it~s low value


  create-organisms1 alliens-nr
  [
    set color allien-color
    ; FOCAL TRAITS
    set body-size allien-body-size
    set interbirth-interval allien-interbirth-interval
    set fecundity allien-fecundity
    set maturity-age allien-maturity-age
    set longevity allien-longevity
    set habitat-spec allien-habitat-spec
    set sexual? allien-sexual?
    set disp-ability allien-disp-ability
    set disp-stage allien-disp-stage
    set climate-optimum allien-climate-optimum
    set climate-sd allien-climate-sd

    ; INITIAL ENERGY AND AGE AND SPATIAL CORDINATES
    set xcor allien-xcor
    set ycor allien-ycor
    set energy allien-energy
    set age allien-age

    ; * BODY-SIZE ^ allometric-constant TRAITS
    set basal-dispersal-cost-per-unit allien-basal-dispersal-cost-per-unit
    set basal-growth-cost-per-tick allien-basal-growth-cost-per-tick
    set basal-homeostasis-cost-per-tick allien-basal-homeostasis-cost-per-tick
    set basal-resource-intake allien-basal-resource-intake

    ; BODY-SIZE SCALING TRAITS (but not allometrically
    set energy-to-reproduce allien-energy-to-reproduce
    set min-energy-after-reprod allien-min-energy-after-reprod
    set ticks-since-last-reproduction 0 ; high value so that organisms automatically reproduce when they can the first time ; now it~s low value

    ; STATS AND VISUALIZATION
    set lineage-identity who
    set size (body-size / 100)
  ]

end


to reset-patch-colors
  ask patches
  [
    set pcolor base-color
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
557
338
895
677
-1
-1
10.0
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
576
226
726
244
Patch initialization
11
0.0
1

SLIDER
571
249
743
282
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
569
285
748
318
num-of-seeds-per-type
num-of-seeds-per-type
1
(world-width * world-height) / num-of-patch-types
11.0
10
1
NIL
HORIZONTAL

BUTTON
894
257
957
290
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
464
373
527
406
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
467
454
530
487
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
387
258
470
303
NIL
count turtles
17
1
11

PLOT
334
501
534
651
mean body-size
NIL
NIL
0.0
10.0
30.0
120.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [body-size] of turtles"

PLOT
251
338
451
488
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

MONITOR
758
204
992
249
seeds for complete random map:
(world-width * world-height) / num-of-patch-types
0
1
11

MONITOR
382
210
484
255
green patches
count patches with [pcolor = green]
17
1
11

PLOT
121
500
321
650
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
46
339
246
489
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
127
160
327
310
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
1137
108
1337
258
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
"max" 1.0 0 -7500403 true "" "plot max [age] of turtles"

SLIDER
632
707
804
740
mortality-rate
mortality-rate
0
1
0.0
0.01
1
NIL
HORIZONTAL

PLOT
1120
654
1320
804
histogram of body sizes
body size value
NIL
1.0
1000.0
0.0
10.0
true
false
"set-plot-pen-mode 1\nset-plot-pen-interval 1" ""
PENS
"default" 1.0 0 -16777216 true "" "histogram [body-size] of turtles"

SWITCH
665
150
913
183
patch-color-scales-with-resources?
patch-color-scales-with-resources?
1
1
-1000

PLOT
1122
345
1322
495
histogram of fecundity
fecundity
NIL
0.0
100.0
0.0
10.0
true
false
"set-plot-pen-mode 1\nset-plot-pen-interval 1" ""
PENS
"default" 1.0 0 -16777216 true "" "histogram [fecundity] of turtles"

SLIDER
906
421
1106
454
resource-perception-radius
resource-perception-radius
0
5
2.0
1
1
NIL
HORIZONTAL

SWITCH
918
466
1057
499
big-move-first?
big-move-first?
0
1
-1000

SWITCH
976
523
1108
556
random-walk?
random-walk?
1
1
-1000

SLIDER
936
597
1108
630
resource-regen-step
resource-regen-step
0
1
0.1
0.1
1
NIL
HORIZONTAL

PLOT
199
677
399
827
mean resources
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
"default" 1.0 0 -16777216 true "" "plot mean [resources] of patches"

PLOT
330
10
530
160
mean interbirth-interval
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
"default" 1.0 0 -16777216 true "" "plot mean [interbirth-interval] of turtles"

BUTTON
918
342
1016
375
degradation
degrade-habitat
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
918
308
1026
341
extermination
exterminate-habitat
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
1036
346
1113
379
invasion
add-invasives
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
934
381
1106
414
alliens-nr
alliens-nr
0
500
100.0
10
1
NIL
HORIZONTAL

BUTTON
1030
306
1161
339
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
918
652
1090
685
hunter-steps
hunter-steps
0
500
60.0
10
1
NIL
HORIZONTAL

SLIDER
787
745
959
778
mutation-size
mutation-size
0
0.5
0.05
0.01
1
NIL
HORIZONTAL

SLIDER
779
92
992
125
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
578
757
756
790
reproductive-cost
reproductive-cost
0
1
0.15
0.01
1
NIL
HORIZONTAL

SLIDER
798
783
978
816
mutation-size-fecundity
mutation-size-fecundity
0.5
5
0.9
0.1
1
NIL
HORIZONTAL

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
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="num-of-patch-types">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="patch-color-scales-with-resources?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mortality-rate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-of-seeds-per-type">
      <value value="1"/>
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
