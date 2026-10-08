# A3 baseline measurements

Current main `0b9d255`, run `20261007-225009`; historical P3 run `20261007-205309`. Raw frames are 1005×565 in both runs. Colour deltas describe pixels, not a causal attribution to an individual merge. Graders differ; this baseline has no /50 or parity re-grade. Surface-class comparisons use different target geometry; walls are reference-only and Sloan’s green-season target compares only sky and concrete numerically.

## compare_runs.py

```text
view                            changed           /50    parity   mock   arch    cal  house/silh/ground
lakeview-postcard-afternoon       73.1%    28.9->None None->None 3->None 3->None   3->3  3->None/2->None/2->None
lakeview-street-afternoon         69.4%    30.0->None None->None 3->None 2->None   3->3  3->None/3->None/2->None
ordinary-street-afternoon         12.5%    30.5->None None->None 3->None 2->None   3->3  2->None/2->None/3->None
wilmette-street-afternoon         13.8%    29.5->None None->None 3->None None->None   3->3  3->None/3->None/3->None

calibration closeness mean over 4 views: 3.00 -> 3.00
```

## region_colours.py

```text

lakeview-street-afternoon   (dE to the mock: 20261007-225009 <- 20261007-205309)
  wall                       16.8 <-  17.6   frame #A46634 #8B5727   mock #A47459   (the wall box often faces away from the sun while the mock paints it lit: wall_variants.py)
  road                       11.0 <-   8.2   frame #7D919E #829097   mock #7B7E7F
  sidewalk                   11.8 <-   9.8   frame #E8E8DF #E7E3D8   mock #D0C7BB
  parkway lawn               16.9 <-  15.4   frame #5C9561 #86AD69   mock #84915D
  near lawn                  17.4 <-  14.6   frame #9DBD78 #A2B978   mock #899562
  crowns                     20.5 <-   5.4   frame #105C00 #56672B   mock #506620
  sky                        11.5 <-  17.2   frame #82BEE8 #66BEE1   mock #70ABE5

lakeview-postcard-afternoon   (dE to the mock: 20261007-225009 <- 20261007-205309)
  wall                       12.4 <-  10.9   frame #9A6449 #754932   mock #815E4E   (the wall box often faces away from the sun while the mock paints it lit: wall_variants.py)
  road                        8.0 <-   4.3   frame #7F919A #778387   mock #7C7F87
  sidewalk                   24.1 <-  21.5   frame #EEEBDF #E5DECC   mock #ADABAE
  parkway lawn               20.6 <-  15.2   frame #8AB06C #819F5B   mock #7C8350
  crowns                     31.6 <-  24.9   frame #2C6F00 #7F9748   mock #4F6334
  sky                        11.6 <-  12.5   frame #7CB5DC #59AAD3   mock #70B6F2

wilmette-street-afternoon   (dE to the mock: 20261007-225009 <- 20261007-205309)
  wall                       28.7 <-  33.8   frame #B69060 #C2945E   mock #90938A   (the wall box often faces away from the sun while the mock paints it lit: wall_variants.py)
  road                        8.7 <-   5.3   frame #62727C #68757A   mock #717976
  sidewalk                   17.7 <-  18.2   frame #E9E5D9 #E9E1CD   mock #BAB5B3
  near lawn                  15.5 <-  17.9   frame #598546 #618944   mock #566F46
  parkway lawn               11.9 <-  14.6   frame #6C9255 #6E924E   mock #7E9266
  crowns                      9.5 <-  10.4   frame #2B4500 #213D00   mock #37541F
  sky                        10.9 <-   9.5   frame #6A9DBF #56A6CF   mock #7FB6E3

ordinary-street-afternoon   (dE to the mock: 20261007-225009 <- 20261007-205309)
  wall                       20.7 <-  19.6   frame #89816D #7F7864   mock #8C5E4A   (the wall box often faces away from the sun while the mock paints it lit: wall_variants.py)
  road                        2.1 <-   4.6   frame #5B6B73 #687578   mock #5F6A70
  sidewalk                    5.5 <-   5.6   frame #D4D2C9 #D8D3C2   mock #D0C5B9
  left lawn                   6.8 <-   7.0   frame #899C5F #91A05C   mock #7E8E4A
  right lawn                  7.4 <-  11.1   frame #6F8D44 #7A9644   mock #778849
  sky                        12.2 <-   8.0   frame #739EBE #80B7D3   mock #8BBDE6

mean dE to the mocks by surface, over the hero views (20261007-225009 <- 20261007-205309):
  wall                       19.7 <-  20.5   (4 regions)
  road                        7.5 <-   5.6   (4 regions)
  sidewalk                   14.8 <-  13.8   (4 regions)
  lawn                       13.8 <-  13.7   (7 regions)
  crowns                     20.5 <-  13.6   (3 regions)
  sky                        11.6 <-  11.8   (4 regions)
```

## calibration_colours.py

```text

lakeview-street-afternoon   (dE to the calibration frame 01-lakeview: 20261007-225009 <- 20261007-205309)
  sky                        12.0 <-  18.4   frame #82BEE8 #66BEE1   calibration #77B0ED   newest run minus calibration: dL +4 da -6 db +9
  road                       12.7 <-  13.2   frame #7D919E #829097   calibration #6A7182   newest run minus calibration: dL +11 da -5 db +1
  sidewalk                   17.7 <-  15.7   frame #E8E8DF #E7E3D8   calibration #CAB7AC   newest run minus calibration: dL +16 da -7 db -4
  parkway lawn               21.2 <-  22.8   frame #5C9561 #86AD69   calibration #717842   newest run minus calibration: dL +8 da -18 db -7
  crowns                     30.8 <-  11.3   frame #105C00 #56672B   calibration #485327   newest run minus calibration: dL +0 da -27 db +16
  wall                       16.4 <-  21.2   frame #A46634 #8B5727   calibration #C08964   newest run minus calibration: dL -13 da +4 db +10   (reference only)

lakeview-postcard-afternoon   (dE to the calibration frame 01-lakeview: 20261007-225009 <- 20261007-205309)
  sky                        12.6 <-  14.0   frame #7CB5DC #59AAD3   calibration #77B0ED   newest run minus calibration: dL +1 da -6 db +11
  road                       13.2 <-  10.3   frame #7F919A #778387   calibration #6A7182   newest run minus calibration: dL +11 da -6 db +3
  sidewalk                   18.4 <-  14.1   frame #EEEBDF #E5DECC   calibration #CAB7AC   newest run minus calibration: dL +17 da -6 db -2
  parkway lawn               23.5 <-  17.4   frame #8AB06C #819F5B   calibration #717842   newest run minus calibration: dL +19 da -14 db +2
  crowns                     35.6 <-  30.8   frame #2C6F00 #7F9748   calibration #485327   newest run minus calibration: dL +8 da -27 db +22
  wall                       14.8 <-  27.0   frame #9A6449 #754932   calibration #C08964   newest run minus calibration: dL -14 da +2 db -4   (reference only)

wilmette-street-afternoon   (dE to the calibration frame 01-lakeview: 20261007-225009 <- 20261007-205309)
  note: The pack has no Wilmette frame; the Chicago frame is the nearest regional look. Its walls are profile colours, not calibration content.
  sky                        16.5 <-  14.3   frame #6A9DBF #56A6CF   calibration #77B0ED   newest run minus calibration: dL -8 da -6 db +13
  road                        5.5 <-   7.7   frame #62727C #68757A   calibration #6A7182   newest run minus calibration: dL -1 da -5 db +3
  sidewalk                   16.4 <-  15.3   frame #E9E5D9 #E9E1CD   calibration #CAB7AC   newest run minus calibration: dL +15 da -6 db -2
  parkway lawn               15.3 <-  15.8   frame #6C9255 #6E924E   calibration #717842   newest run minus calibration: dL +8 da -13 db -1
  crowns                     15.2 <-  15.6   frame #2B4500 #213D00   calibration #485327   newest run minus calibration: dL -7 da -9 db +10

ordinary-street-afternoon   (dE to the calibration frame 06-sloans: 20261007-225009 <- 20261007-205309)
  note: 06-sloans is a lakeside path (autumn engine frame, green-season calibration): only sky and the concrete path are comparable.
  sky                         9.4 <-  11.1   frame #739EBE #80B7D3   calibration #7CADDB   newest run minus calibration: dL -6 da -2 db +7
  sidewalk                   16.9 <-  14.6   frame #D4D2C9 #D8D3C2   calibration #D2B49B   newest run minus calibration: dL +9 da -8 db -12

mean dE to the calibration frames by surface, over the hero views (20261007-225009 <- 20261007-205309); walls excluded:
  sky                        12.6 <-  14.4   (4 regions)   newest run minus calibration: dL -2 da -5 db +10
  road                       10.5 <-  10.4   (3 regions)   newest run minus calibration: dL +7 da -5 db +2
  sidewalk                   17.3 <-  14.9   (4 regions)   newest run minus calibration: dL +14 da -7 db -5
  lawn                       20.0 <-  18.7   (3 regions)   newest run minus calibration: dL +12 da -15 db -2
  crowns                     27.2 <-  19.2   (3 regions)   newest run minus calibration: dL +0 da -21 db +16
```
