# Can You See The Change? Change Point Detection Using Visual Inference
Miguel Fudolig, Emily A. Robinson, and Susan VanderPlas

## Supplementary Material

+ **Participant Data:** De-identified participant data collected in the study and used for analyses are available in `changepoint-lineup-data.csv`.

+ **Data Analysis Code:** The code used to replicate the analysis in this paper can be in `changepoint-lineup-analysis.qmd`.

+ **Simulated Lineup Data:** The generated `x` and `y` points used in plotting the lineups and calculating comparisons to change point analysis can be found in a zip file `lineup-data.zip`.

+ **Study Applet Code:** The code used to create the study applet via RShiny can be found on GitHub at <https://github.com/earobinson95/change-point-detection-lineup-study-applet>


## Participant Data Contents

+ **participant_id:** provides the unique participant identifier   
+ **nlineups:** total number of lineups evaluated by that participant        
+ **age:** indicates the participants age range.              
+ **gender:** indicates the gender the participant identifies by.
+ **academic_study:** indicates the level of education the participant has completed.   
+ **health_related:** indicates the whether the participant works in a health related field.    
+ **stem_related:** indicates whether the participant works in a stem related field.        
+ **recruited:** indicates how the participant was recruited for the study.        
+ **bib_id:** the block id randomly assigned to the participant.   
+ **lineup_order:** the order in which the participant evaluated the lineup.   
+ **lineup_id:** unique identifier to link the participant data to the lineup `.svg` file for the study.          
+ **dataset_id:** unique identifier for a specific simulated data set plotted in the statistical lineups (combination of version, change point location, theta, and sigma).     
+ **param_id:** unique identifier for the combination of version, change point location, theta, and sigma.         
+ **theta:** both the direction and magnitude of the mean shift used to simulate the change point data.            
+ **theta_abs:** the magnitude of the mean shift ($\theta =$ `1`, `3`, `5`).        
+ **direction:** the direction of the mean shift (`positive`/`negative`)        
+ **cpLoc:**  the relative position along the x-axis in which the change point occurs (cpLoc = `0.33`, `0.5`, `0.66`)          
+ **sigma:**            
+ **version:** indicates the simulated replication of each factor combination.          
+ **obs_plot_location:** the lineup panel containing the change point data.
+ **response_no:** the lineup panel selected by the participant.      
+ **correct:** indicates whether or not the participant correctly identified the target panel ($1 = $ correct and $0 = $ incorrect).         
+ **conf_level:** provides the participants confidence level selection in identifying the target panel.      
+ **choice_reason:** provides the participants reason(s) for selecting the panel they did for the target.
