/**
 * jspsych-continuous-color
 * plugin for continuous color report using Schurgin et al. color wheel.
 * @author Tim Brady, Janna Wennberg
 * Original code by Tim Brady Dec. 2020, 
 * adapted for jsPsych 7.2 and retrocue added by Janna Wennberg, June 2022
 * adapted by Holly Kular 6/2023 for orientation wm continuous report with distractors

*/


var css_added = false;

var jsPsychSequentialContinuousReport = (function (jsPsych) {

    const info = {
        name: 'sequential-continuous', /* will probably rename */
        parameters: {
            /** The image to be displayed */
          stimulus: {
              type: jspsych.ParameterType.IMAGE,
              pretty_name: "Stimulus",
              default: undefined,
          },
          /** Set the image height in pixels */
          stimulus_height: {
              type: jspsych.ParameterType.INT,
              pretty_name: "Image height",
              default: null,
          },
          /** Set the image width in pixels */
          stimulus_width: {
              type: jspsych.ParameterType.INT,
              pretty_name: "Image width",
              default: null,
          },
          /** Maintain the aspect ratio after setting width or height */
          maintain_aspect_ratio: {
              type: jspsych.ParameterType.BOOL,
              pretty_name: "Maintain aspect ratio",
              default: true,
          },
          /** Array containing the key(s) the subject is allowed to press to respond to the stimulus. */
          choices: {
              type: jspsych.ParameterType.KEYS,
              pretty_name: "Choices",
              default: "ALL_KEYS",
          },
          /** If true, trial will end when subject makes a response. */
          response_ends_trial: {
            type: jspsych.ParameterType.BOOL,
            pretty_name: "Response ends trial",
            default: true,
        },
        /**
         * If true, the image will be drawn onto a canvas element (prevents blank screen between consecutive images in some browsers).
         * If false, the image will be shown via an img element.
         */
        render_on_canvas: {
            type: jspsych.ParameterType.BOOL,
            pretty_name: "Render on canvas",
            default: true,
        },
            /*display_set_size: {
                type: jsPsych.ParameterType.INT,
                pretty_name: 'Display set size',
                default: 2,
                description: 'Number of items to show on this trial'
            }, will probably not need because set size 1*/
            /*memory_set_size: {
                type: jsPsych.ParameterType.INT,
                pretty_name: 'Memory set size',
                default: 2,
                description: 'Number of items to retro-cue'
            }, only doing set size 1*/
            /*feature_cue: {
                type: jsPsych.ParameterType.INT,
                pretty_name: 'Feature to cue',
                default: 3,
                description: 'Which feature to cue (1=ori, 2=color, 3=both)'
            },
            feature_recall: {
                type: jsPsych.ParameterType.INT,
                pretty_name: 'Feature to recall',
                default: 1,
                description: 'Which feature to recall (1=ori, 2=color)'
            },
            feature_separate_objects: {
                type: jsPsych.ParameterType.BOOL,
                pretty_name: 'Recall features on separate objects?',
                default: true,
                description: 'Recall features on separate objects (only for feature_cue == 3)'
            }, not doing a retrocue or any other features besides 1 ori*/
            target_angles: {
                type: jsPsych.ParameterType.INT,
                pretty_name: 'Actual oris to show (optional)',
                default: [],
                array: true,
                description: 'If not empty, should be a list of oris to show, in degrees, of same length as set_size. If empty, random oris with min distance between them of min_difference [option below] will be chosen. '
            },
            target_kappa: {
                type: jsPsych.ParameterType.INT,
                pretty_name: 'Actual kappa to show (necessary)',
                default: [],
                description: 'If not empty, should select kappa for image for target presentation. '
            },
            distractor_cond: {
                type: jsPsych.ParameterType.INT,
                pretty_name: 'Actual distractor condition to show (necessary)',
                default: [],
                description: 'If not empty, should select image for delay presentation. '
            },
            /*item_colors: {
                type: jsPsych.ParameterType.INT,
                pretty_name: 'Actual colors to show (optional)',
                default: [],
                array: true,
                description: 'If not empty, should be a list of colors to show, in degrees of color wheel, of same length as set_size. If empty, random colors with min distance between them of min_difference [option below] will be chosen. '
            },
            item_positions: {
                type: jsPsych.ParameterType.INT,
                pretty_name: 'Positions of items (optional)',
                default: [],
                array: true,
                description: 'If not empty, should be where, from 0 to placeholders-1, each item from target_angles goes. '
            },*/
            probe_position: {
                type: jsPsych.ParameterType.INT,
                pretty_name: 'Position of items to be recalled',
                default: 0,
                description: 'Which item (1 = first, 2 = second) item(s) are cued. '
            },
            click_to_start: {
                type: jsPsych.ParameterType.BOOL,
                pretty_name: 'Click to start trial or start on a timer?',
                default: true,
                description: 'Click to start trial or start on a delay_start ms timer?'
            },
            delay_start: {
                type: jsPsych.ParameterType.INT,
                pretty_name: 'Delay before starting trial',
                default: 1000,
                description: 'Delay before starting trial'
            },
            feedback: {
                type: jsPsych.ParameterType.BOOL,
                pretty_name: 'Give feedback?',
                default: true,
                description: 'Feedback will be in deg. of error.'
            },
            item_size: {
                type: jsPsych.ParameterType.INT,
                pretty_name: 'Size of each item',
                default: 180, /* maybe change this */
                description: 'Diameter of each circle in pixels.'
            },
            display_time: {
                type: jsPsych.ParameterType.INT,
                pretty_name: 'Time to show oris',
                default: 750, /* maybe change this */
                description: 'Time in ms. to display oris'
            },
            isi_time: {
                type: jsPsych.ParameterType.INT,
                pretty_name: 'Inter-stimulus interval',
                default: 500, /* maybe change this */
                description: 'Time in ms. between target and delay stim'
            },
            pre_response_time: {
                type: jsPsych.ParameterType.INT,
                pretty_name: 'Time until response',
                default: 50,
                description: 'Time in ms between offset of delay and response'
            },
            /*pre_retrocue_time: {
                type: jsPsych.ParameterType.INT,
                pretty_name: 'Time until retrocue',
                default: 500,
                description: 'Time in ms between offset of second stim and RC'
            },
            retrocue_time: {
                type: jsPsych.ParameterType.INT,
                pretty_name: 'Retro-cue time',
                default: 1000,
                description: 'Time in ms to display retro-cue'              
            },
            post_retrocue_time: {
                type: jsPsych.ParameterType.INT,
                pretty_name: 'Time until probe',
                default: 1000,
                description: 'Time in ms between offset of retrocue and probe'
            },*/
            pre_wiggle_time: {
                type: jsPsych.ParameterType.INT,
                pretty_name: 'Time until wiggle',
                default: 500,
                description: 'Time in ms between offset of target and delay wiggle'
            },
            wiggle_time: {
                type: jsPsych.ParameterType.INT,
                pretty_name: 'Time duration wiggle',
                default: 30,
                description: 'Time in ms of delay wiggle'
            },
            delay_time: {
                type: jsPsych.ParameterType.INT,
                pretty_name: 'Time length of delay',
                default: 500,
                description: 'Time in ms between offset of target and response'
            },
            post_wiggle_time: {
                type: jsPsych.ParameterType.INT,
                pretty_name: 'Time until response',
                default: 500,
                description: 'Time in ms between offset of delay wiggle and response'
            },
            response_time: {
                type: jsPsych.ParameterType.INT,
                pretty_name: 'Time of response',
                default: 500,
                description: 'Time in ms between offset of delay and iti'
            },
            radius: {
                type: jsPsych.ParameterType.INT,
                pretty_name: 'Where items appear',
                default: 160,
                description: 'Radius in pixels of circle items appear along.'
            },
            /*num_placeholders: {
                type: jsPsych.ParameterType.INT,
                pretty_name: 'Number of locations where items can appear',
                default: 2,
                description: 'Number of locations where items can appear'
            },*/
            min_difference: {
                type: jsPsych.ParameterType.INT,
                pretty_name: 'Min difference between different items',
                default: 15,
                description: 'Min difference between items in degrees of ori space (to reduce grouping).'
            },
            bg_color: {
                type: jsPsych.ParameterType.STRING,
                pretty_name: 'BG color of box for experiment',
                default: '#848484', /* should match BG of targets */
                description: 'BG color of box for experiment.'
            }
        }
    };
    class SequentialConjunctionPlugin {
        constructor(jsPsych) {
            this.jsPsych = jsPsych;
        }

        trial(display_element, trial) {
            /* Add CSS for classes just once when
            plugin is first used:
            --------------------------------*/
            if (!css_added) {
                var css = `
            .contMemoryOri {
            position: absolute;
            transform-origin: center;
            background: '';
            z-index = -1;}
                
            .contMemoryChoice {
            width: 20px;
            height: 20px;
            border-radius: 50%;
            cursor: pointer;
            font-size: 10pt;
            display: flex;
            align-items: center;
            justify-content: center;
            z-index = -1;}

            #contMemoryBox {
            display: flex;
            margin: 0 auto;
            align-items: center;
            justify-content: center;  
            border: 1px solid black;
            background: ${trial.bg_color};
            position: relative;
            z-index = -2;}`;

                var styleSheet = document.createElement("style");
                styleSheet.type = "text/css";
                styleSheet.innerText = css;
                document.head.appendChild(styleSheet);
                css_added = true;
            }

            /* Build basic trial structure:
            -------------------------------- */
            var width = trial.radius * 2 + trial.item_size * 2 + 50;
            var height = trial.radius * 2 + trial.item_size * 2 + 50;
            var center = width / 2;
            var startText = "Click the + to start this trial.";
            if (!trial.click_to_start) { startText = ""; }
            var html = `
            <div id="contMemoryBox" style="
            width:${width}px; 
            height: ${height}px;">`;

            var curTop = center - trial.item_size/2; 
            var curLeft = center - trial.item_size/2;

            html += `<div id="ori" class="contMemoryOri" 
            style="top:${curTop + (trial.item_size / 2) - trial.item_size / 24}px; left:${curLeft}px; 
            width:${trial.item_size}px; 
            height:${trial.item_size / 12}px";></div>`

            html += `<span id="contMemoryFixation" style="cursor: pointer; z-index: 0">+</span>
            <div id="contMemoryStartTrial" style="position: absolute; 
            top:20px">${startText}</div>
            <div id="reportDiv"></div>
            <div id="contMemoryFeedback" style="position: absolute; 
            top:80px";></div>
            </div>`;
            
            display_element.innerHTML = html;

            /* Wait for click to start the trial:
            -------------------------------- */
            var startTrial = () => {
                document.getElementById("contMemoryStartTrial").style.display = 'none';
                if (trial.click_to_start) {
                    display_element.querySelector('#contMemoryFixation').removeEventListener('click', startTrial);
                }
                document.getElementById("contMemoryFixation").style.cursor = 'auto';
                this.jsPsych.pluginAPI.setTimeout(showTarget(performance.now()), trial.delay_start);
            };
            if (trial.click_to_start) {
                display_element.querySelector('#contMemoryFixation').addEventListener('click', startTrial);
            } else {
                startTrial();
            }

            /* Show the target:
            -------------------------------- */
            /*var item_colors = trial.item_colors;*/
            var item_angles = trial.item_angles;

            if (trial.item_angles.length == 0 /* && trial.item_colors.length == 0*/) {
                item_angles = GetOrisForTrial(trial.set_size, trial.min_difference);
                /*item_colors = GetColorsForTrial(trial.set_size, trial.min_difference);*/
            }


            var start_request_anim;
            var last_frame_time;

            function showTarget(ts) {
                if (trial.display_time > 0) {
                    /*SetColor('ori', item_colors[0]);*/
                    document.getElementById('ori').style.transform = 'rotate(' + -1 * target_angles[0] + 'deg)';
                }
                start_request_anim = ts;
                last_frame_time = ts;
                hideTarget(ts);
            };

            /* Wait until time to hide stimuli:
        -------------------------------- */
            var actual_targ_duration;
            var actual_dist_duration;

            var hideTarget = function (ts) {
                var last_frame_duration = ts - last_frame_time;
                last_frame_time = ts;
                if (ts - start_request_anim
                    >= trial.display_time - (last_frame_duration / 2)) {
                    actual_targ_duration = ts - start_request_anim;
                    for (var i = 0; i < trial.set_size; i++) {
                        document.getElementById('ori').style.backgroundColor = '';
                    }
                    requestAnimationFrame(interstimulusInterval);
                } else {
                    requestAnimationFrame(hideTarget);
                }
            }

            var interstimulusInterval = function (ts) {
                var last_frame_duration = ts - last_frame_time;
                last_frame_time = ts;
                if (ts - start_request_anim
                    >= trial.display_time + trial.isi_time - (last_frame_duration / 2)) {
                    showDistractor(performance.now());
                } else {
                    requestAnimationFrame(interstimulusInterval);
                }               
            }

            function showDistractor(ts) {
                if (trial.display_time > 0) {
                    /*SetColor('ori', item_colors[1]);*/
                    document.getElementById('ori').style.transform = 'rotate(' + -1 * target_angles[1] + 'deg)';
                }
                start_request_anim = ts;
                last_frame_time = ts;
                hideDistractor(ts);
            };

            var hideDistractor = function (ts) {
                var last_frame_duration = ts - last_frame_time;
                last_frame_time = ts;
                if (ts - start_request_anim
                    >= trial.display_time - (last_frame_duration / 2)) {
                    actual_dist_duration = ts - start_request_anim;
                    for (var i = 0; i < trial.set_size; i++) {
                        document.getElementById('ori').style.backgroundColor = '';
                    }
                    requestAnimationFrame(delayUntilResponse);
                } else {
                    requestAnimationFrame(hideDistractor);
                }
            }

            /*var delayUntilResponse = function (ts) {
                var last_frame_duration = ts - last_frame_time;
                last_frame_time = ts;
                if (ts - start_request_anim
                    >= trial.display_time + trial.pre_response_time - (last_frame_duration / 2)) {
                    showRespone(performance.now());
                    //setTimeout(endTrial,1000)
                } else {
                    requestAnimationFrame(delayUntilResponse);
                }
            } */


            /*var showRetrocue = (ts) => {
                if (trial.feature_cue == 1) {
                    if (trial.memory_set_size == 1){
                        document.getElementById('contMemoryFixation').innerHTML = "<br><br><br>O"+(trial.probe_position);
                    } else if (trial.memory_set_size == 2){
                        document.getElementById('contMemoryFixation').innerHTML = "<br><br><br>O1, O2";
                    }
                }
                else if (trial.feature_cue == 2) {
                    if (trial.memory_set_size == 1){
                        document.getElementById('contMemoryFixation').innerHTML = "<br><br><br>C"+(trial.probe_position);
                    } else if (trial.memory_set_size == 2){
                        document.getElementById('contMemoryFixation').innerHTML = "<br><br><br>C1, C2";
                    }
                } else if (trial.feature_cue == 3 && trial.feature_separate_objects == false) {
                    document.getElementById('contMemoryFixation').innerHTML = "<br><br><br>O"+(trial.probe_position)+", C"+(trial.probe_position);
                } else if (trial.feature_cue == 3 && trial.feature_separate_objects == true && trial.feature_recall == 1) {
                    document.getElementById('contMemoryFixation').innerHTML = "<br><br><br>O" + (trial.probe_position) + ", C"+(3-trial.probe_position);
                } else if (trial.feature_cue == 3 && trial.feature_separate_objects == true && trial.feature_recall == 2) {
                    document.getElementById('contMemoryFixation').innerHTML = "<br><br><br>O" + (3-trial.probe_position) + ", C"+(trial.probe_position);

                }
                
                start_request_anim = ts;
                last_frame_time = ts;
                hideRetrocue(ts);
            }

            
            var hideRetrocue = (ts) => {
                var last_frame_duration = ts - last_frame_time;
                last_frame_time = ts;
                if (ts - start_request_anim
                    >= trial.retrocue_time - (last_frame_duration / 2)) {
                    document.getElementById('contMemoryFeedback').innerHTML = ' ';

                    requestAnimationFrame(delayUntilProbe);
                } else {
                    requestAnimationFrame(hideRetrocue);
                }
            }*/
            //
            
            // Wait until time to show probe:
        //-------------------------------- 
            function delayUntilResponse(ts) { 
                var last_frame_duration = ts - last_frame_time;
                last_frame_time = ts;
                if (ts - start_request_anim
                    >= trial.delay_time + trial.post_wiggle_time - (last_frame_duration / 2)) {
                    //setTimeout(endTrial,1000)
                    getResponse();
                } else {
                    requestAnimationFrame(delayUntilResponse);
                }
            }

            
            // Show response wheel:
            //-------------------------------- 
            var wheel_radius = trial.radius + 100;
            //var wheel_radius = trial.item_size/2 + 50;
            
            var response_angle;
            var start_time;
            
            var probe_angle = new Array();
            if (trial.feature_recall == 1){
                probe_angle.push(target_angles[trial.probe_position-1]);
            }else{
                probe_angle.push(item_colors[trial.probe_position-1]);
            }
            var getResponse = function () {
                var html = `<div id='backgroundRing' 
                style='border: 2px solid gray;
                border-radius: 50%;
                position: absolute;
                top: ${center - wheel_radius}px;
                left: ${center - wheel_radius}px;
                width: ${wheel_radius * 2}px;
                height: ${wheel_radius * 2}px';
                </div>`;
                // Now make wheel html: 
                
                for (var i = 0; i < 360; i++) { 
                    var deg = wrap(i,360); 
                    var topPx = center - 110 - wheel_radius * Math.sin(deg / 180.0 * Math.PI);
                    var leftPx = center - 110 + wheel_radius * Math.cos(deg / 180.0 * Math.PI);

                    //if (trial.feature_recall == 1) {
                        html += `<div class='contMemoryChoice' oriClicked='${deg}' 
                        id='oriRing${deg}' style='position:absolute;
                        background-color: black; top: ${topPx}px; left: ${leftPx}px;'></div>`;
                   /* } else {
                        var col = getColor(deg);
                        html += `<div class='contMemoryChoice' colorClicked='${deg}' 
                        id='colorRing${deg}' style='position:absolute;
                        background-color: rgb(${Math.round(col[0])}, ${Math.round(col[1])}, 
                        ${Math.round(col[2])}); top: ${topPx}px; left: ${leftPx}px;'></div>`;
                    }*/
                }
                document.getElementById('reportDiv').innerHTML = html;
                //if (trial.feature_recall == 1){
                    document.getElementById('contMemoryFixation').innerHTML =
                            "Report O"+(trial.probe_position);
                /*} else{
                    document.getElementById('contMemoryFixation').innerHTML =
                            "Report C"+(trial.probe_position);
                }*/  
                start_time = performance.now(); 
                //if (trial.feature_recall == 1){
                Array.from(document.getElementsByClassName("contMemoryChoice")).forEach(function (e) {
                    e.addEventListener('click', judge_response_ori);
                });
                /*} else {
                Array.from(document.getElementsByClassName("contMemoryChoice")).forEach(function (e) {
                    e.addEventListener('click', judge_response_color);
                });}*/
                
            };
            
            
            // Calc. error & give feedback 
            var trial_errs = new Array();
            var angle_clicked = new Array();
            var angle_clicked_wrapped = new Array();
            var end_click_times = new Array();
            var judge_response_ori = function(e)  {
                end_click_times.push(performance.now() - start_time);
                var angleClicked = this.getAttribute("oriClicked");
                document.getElementById('oriRing' + angleClicked).
                    removeEventListener('click', judge_response_ori);

                angle_clicked.push(parseInt(angleClicked));
                angle_clicked_wrapped.push(wrap(angle_clicked,180));


                if (trial.which_test == -1) {
                    var err = undefined;
                } else {
                    var err = Math.round(angle_clicked_wrapped)
                        - probe_angle;
                    if (err > 90) { err -= 180; }
                    if (err <= -90) { err += 180; }
                }
                trial_errs.push(err);

                Array.from(document.getElementsByClassName("contMemoryChoice")).forEach(function (e) {
                    e.removeEventListener('click', judge_response_ori);
                });
                if (trial.feedback) {
                    var ringClick1 = document.getElementById('oriRing' + probe_angle);
                    var ringClick2 = document.getElementById('oriRing' + (probe_angle[0] + 180));
                    ringClick1.style.border = '4px solid white';
                    ringClick1.style.zIndex = 100;
                    ringClick2.style.border = '4px solid white';
                    ringClick2.style.zIndex = 100;

                    document.getElementById('contMemoryFixation').innerHTML =
                            "You were off by<br>" + Math.abs(err) + " degrees. <br>The correct response is shown.";
                    
                    setTimeout(endTrial, 1500);
                    
                } else {
                    setTimeout(endTrial, 100);
                }
            };
            
            /*var judge_response_color = function(e)  {
                end_click_times.push(performance.now() - start_time);
                var angleClicked = this.getAttribute("colorClicked");
                document.getElementById('colorRing' + angleClicked).
                    removeEventListener('click', judge_response_color);

                angle_clicked.push(parseInt(angleClicked));
                angle_clicked_wrapped.push(wrap(angle_clicked,360));

                    var err = Math.round(wrap(angle_clicked,360))
                        - probe_angle;
                    if (err > 180) { err -= 360; }
                    if (err <= -180) { err += 360; }
                trial_errs.push(err);

                Array.from(document.getElementsByClassName("contMemoryChoice")).forEach(function (e) {
                    e.removeEventListener('click', judge_response_color);
                });
                
                if (trial.feedback) {
                    //SetColor('item' + pos[0], item_colors[0]);
                    var ringClick = document.getElementById('colorRing' + probe_angle);
                    ringClick.style.border = '4px solid black';
                    ringClick.style.zIndex = 100;
                    document.getElementById('contMemoryFixation').innerHTML =
                            "You were off by<br>" + Math.abs(err) + " degrees. <br>The correct response is shown.";
                    setTimeout(endTrial, 1500);
                    
                } else {
                    setTimeout(endTrial, 100);
                }
                
            };*/
            
            // End trial and record information:
            //-------------------------------- 
            var endTrial = () => {
                var trial_data = {
                    "rt": end_click_times,
                    /*"probe_position": trial.probe_position,*/
                    "target_angles": target_angles,
                    /*"item_colors": item_colors,*/
                    "probe_angle": probe_angle,
                    "reported_angle": angle_clicked,
                    "reported_angle_wrapped": angle_clicked_wrapped,
                    "trial_error": trial_errs,
                    /*"memory_set_size": trial.memory_set_size,*/
                    //"feature_cue": trial.feature_cue,
                    //"feature_recall": trial.feature_recall,
                    //"feature_separate_objects": trial.feature_separate_objects,
                    "display_time": trial.display_time,
                    "actual_target_duration": actual_target_duration,
                    "actual_delay_duration": actual_delay_duration,
                    "interstimulus_interval": trial.isi_time,
                    "pre_wiggle_time": trial.pre_wiggle_time,
                    "delay_time": trial.delay_time,
                    "post_wiggle_time": trial.post_wiggle_time
                };
                display_element.innerHTML = '';
                this.jsPsych.finishTrial(trial_data);
            };

        }
    }
    /* Helper functions
     ------------------------------ */

    /* Set an element to a color given in degrees of color wheel */
    function SetColor(id, deg) {
        deg = (deg >= 360) ? deg - 360 : deg;
        deg = (deg < 0) ? deg + 360 : deg;
        var col = getColor(deg);
        document.getElementById(id).style.backgroundColor = 'rgb('
            + Math.round(col[0]) + ','
            + Math.round(col[1]) + ','
            + Math.round(col[2]) + ')';
    }

    /* Get colors subject to constraint that all items are a min.
      difference from each other: */
    function GetColorsForTrial(setSize, minDiff) {
        var items = [];
        var whichCol = getRandomIntInclusive(0, 359);
        items.push(whichCol);

        for (var j = 1; j <= setSize - 1; j++) {
            var validColors = new Array();
            for (var c = 0; c < 360; c++) {
                var isValid = !tooClose(whichCol, c, minDiff);
                for (var testAgainst = 0; testAgainst < j; testAgainst++) {
                    if (isValid && tooClose(items[testAgainst], c, minDiff)) {
                        isValid = false;
                    }
                }
                if (isValid) {
                    validColors.push(c);
                }
            }

            validColors = this.jsPsych.randomization.repeat(validColors, 1);
            items.push(validColors[0]);
        }
        return items;
    }


    /* Get angles subject to constraint that all items are a min.
      difference from each other: */
    function GetOrisForTrial(setSize, minDiff) {
        var items = [];
        var whichAngle = getRandomIntInclusive(0, 179);
        items.push(whichAngle);

        for (var j = 1; j <= setSize - 1; j++) {
            var validAngles = new Array();
            for (var c = 0; c < 180; c++) {
                var isValid = !tooClose(whichAngle, c, minDiff);
                for (var testAgainst = 0; testAgainst < j; testAgainst++) {
                    if (isValid && tooClose(items[testAgainst], c, minDiff)) {
                        isValid = false;
                    }
                }
                if (isValid) {
                    validAngles.push(c);
                }
            }

            validAngles = this.jsPsych.randomization.repeat(validAngles, 1);
            items.push(validAngles[0]);
        }
        return items;
    }

    /* Make sure all numbers in an array are between 0 and 180: */
    function wrap(v, space) {
        if (Array.isArray(v)) {
            for (var i = 0; i < v.length; i++) {
                if (v[i] >= space) { v[i] -= space; }
                if (v[i] < 0) { v[i] += space; }
            }
        } else {
            if (v >= space) { v -= space; }
            if (v < 0) { v += space; }
        }
        return v;
    }

    function getRandomIntInclusive(min, max) {
        min = Math.ceil(min);
        max = Math.floor(max);
        return Math.floor(Math.random() * (max - min + 1)) + min;
    }


    function tooClose(startcol, endcol, minDiff) {
        if (isNaN(startcol) || isNaN(endcol)) {
            return false;
        }
        if (Math.abs(startcol - endcol) <= minDiff) {
            return true;
        }
        if (Math.abs(startcol + 180 - endcol) <= minDiff) {
            return true;
        }
        if (Math.abs(startcol - 180 - endcol) <= minDiff) {
            return true;
        }
        return false;
    }


    SequentialContinuousPlugin.info = info;

    return SequentialContinuousPlugin;
})(jsPsychModule);
