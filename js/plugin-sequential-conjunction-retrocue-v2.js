/**
 * jspsych-continuous-color
 * plugin for continuous color report using Schurgin et al. color wheel.
 * @author Tim Brady, Janna Wennberg
 * Original code by Tim Brady Dec. 2020, 
 * adapted for jsPsych 7.2 and retrocue added by Janna Wennberg, June 2022
 * adapted by Holly Kular 6/2023 for orientation wm continuous report with distractors

*/


var css_added = false;

var jsPsychSequentialConjunctionRetrocue = (function (jsPsych) {

    const info = {
        name: 'sequential-conjunction', /* will probably rename */
        parameters: {
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
            },
            probe_position: {
                type: jsPsych.ParameterType.INT,
                pretty_name: 'Position of items to be recalled',
                default: 0,
                array: true,
                description: 'Which item (1 = first, 2 = second) item(s) are cued. '
            },*/
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
                this.jsPsych.pluginAPI.setTimeout(showFirstItem(performance.now()), trial.delay_start);
            };
            if (trial.click_to_start) {
                display_element.querySelector('#contMemoryFixation').addEventListener('click', startTrial);
            } else {
                startTrial();
            }

            /* Show the items:
            -------------------------------- */
            var item_colors = trial.item_colors;
            var target_angles = trial.target_angles;

            if (trial.target_angles.length == 0 && trial.item_colors.length == 0) {
                target_angles = GetOrisForTrial(trial.set_size, trial.min_difference);
                item_colors = GetColorsForTrial(trial.set_size, trial.min_difference);
            }

            var start_request_anim;
            var last_frame_time;

            function showFirstItem(ts) {
                if (trial.display_time > 0) {
                    SetColor('ori', item_colors[0]);
                    document.getElementById('ori').style.transform = 'rotate(' + -1 * target_angles[0] + 'deg)';
                }
                start_request_anim = ts;
                last_frame_time = ts;
                hideFirstItem(ts);
            };

            /* Wait until time to hide stimuli:
        -------------------------------- */
            var actual_stim1_duration;
            var actual_stim2_duration;

            var hideFirstItem = function (ts) {
                var last_frame_duration = ts - last_frame_time;
                last_frame_time = ts;
                if (ts - start_request_anim
                    >= trial.display_time - (last_frame_duration / 2)) {
                    actual_stim1_duration = ts - start_request_anim;
                    for (var i = 0; i < trial.set_size; i++) {
                        document.getElementById('ori').style.backgroundColor = '';
                    }
                    requestAnimationFrame(interstimulusInterval);
                } else {
                    requestAnimationFrame(hideFirstItem);
                }
            }

            var interstimulusInterval = function (ts) {
                var last_frame_duration = ts - last_frame_time;
                last_frame_time = ts;
                if (ts - start_request_anim
                    >= trial.display_time + trial.isi_time - (last_frame_duration / 2)) {
                    showSecondItem(performance.now());
                } else {
                    requestAnimationFrame(interstimulusInterval);
                }               
            }

            function showSecondItem(ts) {
                if (trial.display_time > 0) {
                    SetColor('ori', item_colors[1]);
                    document.getElementById('ori').style.transform = 'rotate(' + -1 * target_angles[1] + 'deg)';
                }
                start_request_anim = ts;
                last_frame_time = ts;
                hideSecondItem(ts);
            };

            var hideSecondItem = function (ts) {
                var last_frame_duration = ts - last_frame_time;
                last_frame_time = ts;
                if (ts - start_request_anim
                    >= trial.display_time - (last_frame_duration / 2)) {
                    actual_stim2_duration = ts - start_request_anim;
                    for (var i = 0; i < trial.set_size; i++) {
                        document.getElementById('ori').style.backgroundColor = '';
                    }
                    requestAnimationFrame(delayUntilRetrocue);
                } else {
                    requestAnimationFrame(hideSecondItem);
                }
            }

            var delayUntilRetrocue = function (ts) {
                var last_frame_duration = ts - last_frame_time;
                last_frame_time = ts;
                if (ts - start_request_anim
                    >= trial.display_time + trial.pre_retrocue_time - (last_frame_duration / 2)) {
                    showRetrocue(performance.now());
                    //setTimeout(endTrial,1000)
                } else {
                    requestAnimationFrame(delayUntilRetrocue);
                }
            }

            var showRetrocue = (ts) => {
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
            }
            //
            
            // Wait until time to show probe:
        //-------------------------------- 
            function delayUntilProbe(ts) { 
                var last_frame_duration = ts - last_frame_time;
                last_frame_time = ts;
                if (ts - start_request_anim
                    >= trial.retrocue_time + trial.post_retrocue_time - (last_frame_duration / 2)) {
                    //setTimeout(endTrial,1000)
                    getResponse();
                } else {
                    requestAnimationFrame(delayUntilProbe);
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

                    if (trial.feature_recall == 1) {
                        html += `<div class='contMemoryChoice' oriClicked='${deg}' 
                        id='oriRing${deg}' style='position:absolute;
                        background-color: black; top: ${topPx}px; left: ${leftPx}px;'></div>`;
                    } else {
                        var col = getColor(deg);
                        html += `<div class='contMemoryChoice' colorClicked='${deg}' 
                        id='colorRing${deg}' style='position:absolute;
                        background-color: rgb(${Math.round(col[0])}, ${Math.round(col[1])}, 
                        ${Math.round(col[2])}); top: ${topPx}px; left: ${leftPx}px;'></div>`;
                    }
                }
                
                document.getElementById('reportDiv').innerHTML = html;

                if (trial.feature_recall == 1){
                    document.getElementById('contMemoryFixation').innerHTML =
                            "Report O"+(trial.probe_position);
                } else{
                    document.getElementById('contMemoryFixation').innerHTML =
                            "Report C"+(trial.probe_position);
                }
                
                start_time = performance.now();
                
                if (trial.feature_recall == 1){

                Array.from(document.getElementsByClassName("contMemoryChoice")).forEach(function (e) {
                    e.addEventListener('click', judge_response_ori);
                });
                } else {
                Array.from(document.getElementsByClassName("contMemoryChoice")).forEach(function (e) {
                    e.addEventListener('click', judge_response_color);
                });

            }
                
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
            
            var judge_response_color = function(e)  {
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
                
            };
            
            // End trial and record information:
            //-------------------------------- 
            var endTrial = () => {
                var trial_data = {
                    "rt": end_click_times,
                    "probe_position": trial.probe_position,
                    "target_angles": target_angles,
                    "item_colors": item_colors,
                    "probe_angle": probe_angle,
                    "reported_angle": angle_clicked,
                    "reported_angle_wrapped": angle_clicked_wrapped,
                    "trial_error": trial_errs,
                    "memory_set_size": trial.memory_set_size,
                    "feature_cue": trial.feature_cue,
                    "feature_recall": trial.feature_recall,
                    "feature_separate_objects": trial.feature_separate_objects,
                    "display_time": trial.display_time,
                    "actual_stim1_duration": actual_stim1_duration,
                    "actual_stim2_duration": actual_stim2_duration,
                    "interstimulus_interval": trial.isi_time,
                    "pre_retrocue_time": trial.pre_retrocue_time,
                    "retrocue_time": trial.retrocue_time,
                    "post_retrocue_time": trial.post_retrocue_time
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

    function getColor(deg) {
        let colorsList = [
            [246, 37, 111],
            [246, 37, 110],
            [246, 37, 109],
            [246, 37, 107.5],
            [246, 37, 106],
            [246, 37, 104.5],
            [246, 37, 103],
            [246, 37.5, 102],
            [246, 38, 101],
            [246, 38.5, 99.5],
            [246, 39, 98],
            [246, 39.5, 96.5],
            [246, 40, 95],
            [246, 41, 94],
            [246, 42, 93],
            [245.5, 42.5, 91.5],
            [245, 43, 90],
            [245, 44, 89],
            [245, 45, 88],
            [245, 46, 86.5],
            [245, 47, 85],
            [244.5, 47.5, 84],
            [244, 48, 83],
            [243.5, 49, 81.5],
            [243, 50, 80],
            [242.5, 51, 79],
            [242, 52, 78],
            [242, 53, 76.5],
            [242, 54, 75],
            [241.5, 55.5, 74],
            [241, 57, 73],
            [240.5, 58, 71.5],
            [240, 59, 70],
            [239, 60, 69],
            [238, 61, 68],
            [237.5, 62, 66.5],
            [237, 63, 65],
            [236.5, 64, 64],
            [236, 65, 63],
            [235.5, 66, 62],
            [235, 67, 61],
            [234, 68.5, 60],
            [233, 70, 59],
            [232.5, 71, 57.5],
            [232, 72, 56],
            [231, 73, 55],
            [230, 74, 54],
            [229, 75, 53],
            [228, 76, 52],
            [227.5, 77, 51],
            [227, 78, 50],
            [226, 79, 49],
            [225, 80, 48],
            [224, 81, 46.5],
            [223, 82, 45],
            [222, 83, 44],
            [221, 84, 43],
            [220, 85, 42],
            [219, 86, 41],
            [218, 87, 40],
            [217, 88, 39],
            [216, 89, 38],
            [215, 90, 37],
            [214, 91, 36.5],
            [213, 92, 36],
            [212, 93, 35],
            [211, 94, 34],
            [210, 95, 33],
            [209, 96, 32],
            [208, 97, 31],
            [207, 98, 30],
            [205.5, 98.5, 29.5],
            [204, 99, 29],
            [203, 100, 28],
            [202, 101, 27],
            [201, 102, 26.5],
            [200, 103, 26],
            [198.5, 103.5, 25],
            [197, 104, 24],
            [196, 105, 23.5],
            [195, 106, 23],
            [194, 107, 22.5],
            [193, 108, 22],
            [191.5, 108.5, 21.5],
            [190, 109, 21],
            [189, 110, 20.5],
            [188, 111, 20],
            [186.5, 111.5, 19.5],
            [185, 112, 19],
            [183.5, 113, 19],
            [182, 114, 19],
            [181, 114.5, 19],
            [180, 115, 19],
            [178.5, 115.5, 19],
            [177, 116, 19],
            [176, 117, 19],
            [175, 118, 19],
            [173.5, 118.5, 19],
            [172, 119, 19],
            [170.5, 119.5, 19.5],
            [169, 120, 20],
            [168, 120.5, 20.5],
            [167, 121, 21],
            [165.5, 121.5, 21.5],
            [164, 122, 22],
            [162.5, 123, 22.5],
            [161, 124, 23],
            [160, 124.5, 24],
            [159, 125, 25],
            [157.5, 125.5, 25.5],
            [156, 126, 26],
            [154.5, 126.5, 27],
            [153, 127, 28],
            [152, 127.5, 28.5],
            [151, 128, 29],
            [149.5, 128.5, 30],
            [148, 129, 31],
            [146.5, 129, 32],
            [145, 129, 33],
            [144, 129.5, 34],
            [143, 130, 35],
            [141.5, 130.5, 36],
            [140, 131, 37],
            [138.5, 131.5, 38],
            [137, 132, 39],
            [135.5, 132.5, 40],
            [134, 133, 41],
            [133, 133.5, 42.5],
            [132, 134, 44],
            [130.5, 134, 45],
            [129, 134, 46],
            [127.5, 134.5, 47],
            [126, 135, 48],
            [125, 135.5, 49],
            [124, 136, 50],
            [122.5, 136, 51.5],
            [121, 136, 53],
            [119.5, 136.5, 54],
            [118, 137, 55],
            [117, 137, 56.5],
            [116, 137, 58],
            [114.5, 137.5, 59],
            [113, 138, 60],
            [111.5, 138, 61.5],
            [110, 138, 63],
            [109, 138.5, 64],
            [108, 139, 65],
            [106.5, 139, 66.5],
            [105, 139, 68],
            [103.5, 139.5, 69.5],
            [102, 140, 71],
            [101, 140, 72],
            [100, 140, 73],
            [98.5, 140.5, 74.5],
            [97, 141, 76],
            [95.5, 141, 77.5],
            [94, 141, 79],
            [93, 141, 80],
            [92, 141, 81],
            [90.5, 141.5, 82.5],
            [89, 142, 84],
            [88, 142, 85.5],
            [87, 142, 87],
            [85.5, 142, 88.5],
            [84, 142, 90],
            [82.5, 142, 91],
            [81, 142, 92],
            [80, 142, 93.5],
            [79, 142, 95],
            [77.5, 142.5, 96.5],
            [76, 143, 98],
            [75, 143, 99.5],
            [74, 143, 101],
            [72.5, 143, 102.5],
            [71, 143, 104],
            [70, 143, 105],
            [69, 143, 106],
            [67.5, 143, 107.5],
            [66, 143, 109],
            [65, 143, 110.5],
            [64, 143, 112],
            [63, 143, 113.5],
            [62, 143, 115],
            [61, 143, 116],
            [60, 143, 117],
            [58.5, 143, 118.5],
            [57, 143, 120],
            [56, 143, 121.5],
            [55, 143, 123],
            [54, 143, 124.5],
            [53, 143, 126],
            [52.5, 143, 127],
            [52, 143, 128],
            [51, 143, 129.5],
            [50, 143, 131],
            [49.5, 143, 132.5],
            [49, 143, 134],
            [48, 143, 135],
            [47, 143, 136],
            [46.5, 143, 137.5],
            [46, 143, 139],
            [46, 142.5, 140],
            [46, 142, 141],
            [45.5, 142, 142.5],
            [45, 142, 144],
            [45, 142, 145],
            [45, 142, 146],
            [45, 142, 147.5],
            [45, 142, 149],
            [45.5, 141.5, 150],
            [46, 141, 151],
            [46.5, 141, 152.5],
            [47, 141, 154],
            [47.5, 141, 155],
            [48, 141, 156],
            [49, 140.5, 157],
            [50, 140, 158],
            [50.5, 140, 159],
            [51, 140, 160],
            [52, 139.5, 161],
            [53, 139, 162],
            [54.5, 139, 163.5],
            [56, 139, 165],
            [57, 138.5, 165.5],
            [58, 138, 166],
            [59.5, 138, 167],
            [61, 138, 168],
            [62.5, 137.5, 169],
            [64, 137, 170],
            [65.5, 137, 171],
            [67, 137, 172],
            [68.5, 136.5, 173],
            [70, 136, 174],
            [71.5, 135.5, 174.5],
            [73, 135, 175],
            [75, 135, 176],
            [77, 135, 177],
            [78.5, 134.5, 177.5],
            [80, 134, 178],
            [82, 133.5, 179],
            [84, 133, 180],
            [85.5, 132.5, 180.5],
            [87, 132, 181],
            [89, 132, 181.5],
            [91, 132, 182],
            [92.5, 131.5, 182.5],
            [94, 131, 183],
            [96, 130.5, 183.5],
            [98, 130, 184],
            [100, 129.5, 184.5],
            [102, 129, 185],
            [104, 128.5, 185.5],
            [106, 128, 186],
            [107.5, 127.5, 186.5],
            [109, 127, 187],
            [111, 126.5, 187.5],
            [113, 126, 188],
            [115, 125.5, 188],
            [117, 125, 188],
            [119, 124, 188.5],
            [121, 123, 189],
            [123, 122.5, 189],
            [125, 122, 189],
            [127, 121.5, 189],
            [129, 121, 189],
            [130.5, 120.5, 189.5],
            [132, 120, 190],
            [134, 119, 190],
            [136, 118, 190],
            [138, 117.5, 190],
            [140, 117, 190],
            [142, 116.5, 190],
            [144, 116, 190],
            [145.5, 115, 189.5],
            [147, 114, 189],
            [149, 113.5, 189],
            [151, 113, 189],
            [153, 112, 189],
            [155, 111, 189],
            [156.5, 110, 188.5],
            [158, 109, 188],
            [160, 108.5, 188],
            [162, 108, 188],
            [163.5, 107, 187.5],
            [165, 106, 187],
            [167, 105.5, 186.5],
            [169, 105, 186],
            [170.5, 104, 185.5],
            [172, 103, 185],
            [174, 102, 184.5],
            [176, 101, 184],
            [177.5, 100, 183.5],
            [179, 99, 183],
            [180.5, 98, 182.5],
            [182, 97, 182],
            [184, 96, 181.5],
            [186, 95, 181],
            [187.5, 94, 180.5],
            [189, 93, 180],
            [190.5, 92, 179],
            [192, 91, 178],
            [193.5, 90, 177.5],
            [195, 89, 177],
            [196.5, 88, 176],
            [198, 87, 175],
            [199.5, 86, 174.5],
            [201, 85, 174],
            [202.5, 84, 173],
            [204, 83, 172],
            [205, 82, 171],
            [206, 81, 170],
            [207.5, 80, 169],
            [209, 79, 168],
            [210, 78, 167.5],
            [211, 77, 167],
            [212.5, 76, 166],
            [214, 75, 165],
            [215, 73.5, 164],
            [216, 72, 163],
            [217.5, 71, 162],
            [219, 70, 161],
            [220, 69, 159.5],
            [221, 68, 158],
            [222, 67, 157],
            [223, 66, 156],
            [224, 64.5, 155],
            [225, 63, 154],
            [226, 62, 153],
            [227, 61, 152],
            [228, 60, 150.5],
            [229, 59, 149],
            [230, 58, 148],
            [231, 57, 147],
            [232, 56, 146],
            [233, 55, 145],
            [233.5, 54, 143.5],
            [234, 53, 142],
            [235, 51.5, 141],
            [236, 50, 140],
            [236.5, 49, 138.5],
            [237, 48, 137],
            [237.5, 47.5, 136],
            [238, 47, 135],
            [239, 46, 133.5],
            [240, 45, 132],
            [240.5, 44, 131],
            [241, 43, 130],
            [241.5, 42.5, 128.5],
            [242, 42, 127],
            [242.5, 41, 125.5],
            [243, 40, 124],
            [243, 39.5, 123],
            [243, 39, 122],
            [243.5, 38.5, 120.5],
            [244, 38, 119],
            [244.5, 37.5, 118],
            [245, 37, 117],
            [245, 37, 115.5],
            [245, 37, 114],
            [245.5, 37, 112.5]
        ];
        return colorsList[deg];
    }

    SequentialConjunctionPlugin.info = info;

    return SequentialConjunctionPlugin;
})(jsPsychModule);
