/**
 * jspsych-continuous-color
 * plugin for continuous color report using Schurgin et al. color wheel.
 * @author Tim Brady, Janna Wennberg
 * Original code by Tim Brady Dec. 2020, 
 * adapted for jsPsych 7.2 and retrocue added by Janna Wennberg, June 2022
 * adapted for orientation report by Holly Kular June 2023
 * TO DO
 * remove retrocue
 * add center fixation
 * add targets
 * add delay item and wiggle
 * add white response line
 * add keyboard response
  */


var continuous_ori_css_added = false;

var jsPsychContinuousOri = (function (jsPsych) {

    const info = {
        name: 'continuous-ori',
        parameters: {
            set_size: {
                type: jsPsych.ParameterType.INT,
                pretty_name: 'Set size',
                default: 1,
                description: 'Number of actual oris to show on this trial'
            },
            item_angles: {
                type: jsPsych.ParameterType.INT,
                pretty_name: 'Actual oris to show',
                default: [],
                array: true,
                description: 'If not empty, should be a list of oris to show, in degrees. If empty, random oris with min distance between them of min_difference [option below] will be chosen. '
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
                default: false,
                description: 'Feedback will be in deg. of ori of error.'
            },
            ori_wheel_num_options: {
                type: jsPsych.ParameterType.INT,
                pretty_name: 'Size of orientation space',
                default: 180,
                description: 'Number of orientations in the space.'
            },
            ori_wheel_list_options: {
                type: jsPsych.ParameterType.INT,
                pretty_name: 'Which choices to show',
                array: true,
                default: [],
                description: 'If not empty, which options to show, relative to the target (0), ranging from -179 to 180.'
            },
            item_size: {
                type: jsPsych.ParameterType.INT,
                pretty_name: 'Size of each item',
                default: 90,
                description: 'Diameter of each circle in pixels.'
            },
            num_placeholders: {
                type: jsPsych.ParameterType.INT,
                pretty_name: 'Number of locations where items can appear',
                default: 1,
                description: 'Number of locations where items can appear'
            },
            display_time: {
                type: jsPsych.ParameterType.INT,
                pretty_name: 'Time to show oris',
                default: 500,
                description: 'Time in ms. to display oris'
            },
            delay_time: {
                type: jsPsych.ParameterType.INT,
                pretty_name: 'Time to show delay screen',
                default: 3500,
                description: 'Time in ms to display delay screen'
            },
            pre_wiggle_delay: {
                type: jsPsych.ParameterType.INT,
                pretty_name: 'Time before cue appears',
                default: 1000,
                description: 'Delay time BEFORE retrocue, in ms.'
            },
            post_wiggle_delay: {
                type: jsPsych.ParameterType.INT,
                pretty_name: 'Time before probe appears',
                default: 1000,
                description: 'Delay time AFTER retrocue, in ms.'
            },
            radius: {
                type: jsPsych.ParameterType.INT,
                pretty_name: 'Where items appear',
                default: 160,
                description: 'Radius in pixels of circle items appear along.'
            },
            min_difference: {
                type: jsPsych.ParameterType.INT,
                pretty_name: 'Min difference between different items',
                default: 15,
                description: 'Min difference between items in degrees of ori space (to reduce grouping).'
            },
            bg_color: {
                type: jsPsych.ParameterType.STRING,
                pretty_name: 'BG color of box for experiment',
                default: '#DDDDDD',
                description: 'BG color of box for experiment.'
            }
        }
    };
    class ContinuousOriRetrocuePlugin {
        constructor(jsPsych) {
            this.jsPsych = jsPsych;
        }

        trial(display_element, trial) {
            /* Add CSS for classes just once when
            plugin is first used:
            --------------------------------*/
            if (!continuous_ori_css_added) {
                var css = `
            .contMemoryItem {
            position: absolute;
            border-radius: 50%;
            border: 1px solid #222;}

            .contMemoryOri {
            position: absolute;
            transform-origin: center;
            background: '';}
                
            .contMemoryChoice {
            width: 20px;
            height: 20px;
            border-radius: 50%;
            cursor: pointer;
            font-size: 10pt;
            display: flex;
            align-items: center;
            justify-content: center;}

            #contMemoryBox {
            display: flex;
            margin: 0 auto;
            align-items: center;
            justify-content: center;  
            border: 1px solid black;
            background: ${trial.bg_color};
            position: relative;}`;

                var styleSheet = document.createElement("style");
                styleSheet.type = "text/css";
                styleSheet.innerText = css;
                document.head.appendChild(styleSheet);
                continuous_ori_css_added = true;
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
            var possiblePositions = []; /* just one position */
            for (var i = 0; i < trial.num_placeholders; i++) {
                let curTop = (Math.cos((Math.PI * 2) / (trial.num_placeholders) * i) * trial.radius)
                    - trial.item_size / 2 + center;
                let curLeft = (Math.sin((Math.PI * 2) / (trial.num_placeholders) * i) * trial.radius)
                    - trial.item_size / 2 + center;

                html += `<div id="item${i}" class="contMemoryItem" 
                style="top:${curTop}px; left:${curLeft}px; 
                width:${trial.item_size}px; 
                height:${trial.item_size}px"></div>`; 

                html += `<div id="ori${i}" class="contMemoryOri" 
                style="top:${curTop+(trial.item_size/2)-trial.item_size/24}px; left:${curLeft}px; 
                width:${trial.item_size}px; 
                height:${trial.item_size/12}px"></div>`;

                possiblePositions.push(i);
            }
            html += `<span id="contMemoryFixation" style="cursor: pointer">+</span>
            <div id="contMemoryStartTrial" style="position: absolute; 
            top:20px">${startText}</div>
            <div id="item-1" class="contMemoryItem" 
            style="display: none; top:${center - trial.item_size / 2}px; left:${center - trial.item_size / 2}px; 
            width:${trial.item_size}px; 
            height:${trial.item_size}px; background: #DDDDDD"></div>
            <div id="reportDiv"></div>
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
                this.jsPsych.pluginAPI.setTimeout(showStimuli(performance.now()), trial.delay_start);                
            };
            if (trial.click_to_start) {
                display_element.querySelector('#contMemoryFixation').addEventListener('click', startTrial);
            } else {
                startTrial();
            }

            /* Show the items:
            -------------------------------- */
            var item_angles = trial.item_angles;
            if (trial.item_angles.length == 0) {
                item_angles = GetOrisForTrial(trial.set_size, trial.min_difference);
            }
            var start_request_anim;
            var last_frame_time;

            function showStimuli(ts) {
                if (trial.display_time > 0) {
                    for (var i = 0; i < trial.set_size; i++) {
                        document.getElementById('ori').style.backgroundColor = 'black';
                        document.getElementById('ori').style.transform = 'rotate('+ -1*item_angles[i] + 'deg)'; /* horizontal line rotated */
                    }
                }
                start_request_anim = ts;
                last_frame_time = ts;
                hideStimuli(ts);
            };

            /* Wait until time to hide stimuli:
        -------------------------------- */
            var actual_stim_duration;
            
            var hideStimuli = function (ts) {
                var last_frame_duration = ts - last_frame_time;
                last_frame_time = ts;
                if (ts - start_request_anim
                    >= trial.display_time - (last_frame_duration / 2)) {
                    actual_stim_duration = ts - start_request_anim;
                    for (var i = 0; i < trial.set_size; i++) {
                        document.getElementById('ori' + pos[i]).style.backgroundColor = '';
                    }
                    requestAnimationFrame(delayinterval);
                } else {
                    requestAnimationFrame(hideStimuli);
                }
            }

            var delayinterval = function (ts) {
                var last_frame_duration = ts - last_frame_time;
                last_frame_time = ts;
                if (ts - start_request_anim
                    >= trial.display_time + trial.pre_wiggle_delay - (last_frame_duration / 2)) {
                    showWiggle(performance.now());
                } else {
                    requestAnimationFrame(delayinterval);
                }
            }

            var showWiggle = (ts) => {
                for (var i = 0; i < trial.wiggle; i++){
                    document.getElementById('item' + rc_pos[i]).style.border = '5px solid black';
                }
                start_request_anim = ts;
                last_frame_time = ts;
                hidewiggle(ts);
            }
            
            var hidewiggle = (ts) => {
                var last_frame_duration = ts - last_frame_time;
                last_frame_time = ts;
                if (ts - start_request_anim
                    >= trial.delay_time - (last_frame_duration / 2)) {
                    for (var i = 0; i < trial.wiggle; i++) {
                        document.getElementById('item' + rc_pos[i]).style.border = '1px solid #222';
                    }
                    requestAnimationFrame(delayUntilProbe);
                } else {
                    requestAnimationFrame(hidewiggle);
                }
            }
            
            /* Wait until time to show probe:
        -------------------------------- */
            function delayUntilProbe(ts) { 
                var last_frame_duration = ts - last_frame_time;
                last_frame_time = ts;
                if (ts - start_request_anim
                    >= trial.delay_time + trial.post_wiggle_delay - (last_frame_duration / 2)) {
                    getResponse();
                } else {
                    requestAnimationFrame(delayUntilProbe);
                }
            }


            /* Show response line: !!! make this a line !!!
            -------------------------------- */
            var line_radius = trial.item_size/2 + 50;
            var line_width = 2; /* is this in pixels?!!! */
            var line_pos = ; /* center */
            var line_top = (Math.sin((Math.PI * 2) / (trial.num_placeholders) * line_pos) * trial.radius)
            - line_radius + center;;
            var line_left = (Math.cos((Math.PI * 2) / (trial.num_placeholders) * line_pos) * trial.radius)
            - line_radius + center;
            var start_time;
            
            var getResponse = function () {
                
                var html = `<div id='backgroundRing' 
                style='border: 2px solid gray;
                border-radius: 50%;
                position: absolute;
                top: ${wheel_top + 3}px;
                left: ${wheel_left + 3}px;
                width: ${wheel_radius * 2}px;
                height: ${wheel_radius * 2}px';
                </div>`;
                /* Now make line html:  !!!! fix this */
                for (var i = 0; i < 360; i++) { // i < wheelOptions.length
                    var deg = wrap(i,360); // var deg = wrap(wheelOptions[i]);
                    //var topPx = center - 10 - wheel_radius * Math.sin(deg / 180.0 * Math.PI);
                    //var leftPx = center - 10 + wheel_radius * Math.cos(deg / 180.0 * Math.PI);
                    var topPx = wheel_radius - 10 - wheel_radius * Math.sin(deg / 180.0 * Math.PI);
                    var leftPx = wheel_radius - 10 + wheel_radius * Math.cos(deg / 180.0 * Math.PI);
                    html += `<div class='contMemoryChoice' oriClicked='${deg}' 
                id='oriRing${deg}' style='position:absolute;
                background-color: black; top: ${topPx}px; left: ${leftPx}px;'></div>`;
                }
                document.getElementById('reportDiv').innerHTML = html;
                start_time = performance.now();
                
                if (trial.which_test == -1) {
                    document.getElementById('item-1').style.display = 'block';
                    document.getElementById('item-1').style.border = '5px solid black';
                } else {
                    document.getElementById('item' + pos[trial.which_test]).style.border = '5px solid black';
                }
                
                //document.addEventListener('mousemove', updateAngle);
                Array.from(document.getElementsByClassName("contMemoryChoice")).forEach(function (e) {
                    e.addEventListener('click', judge_response);
                });
            };
            
            
            /* Calc. error & give feedback */
            var trial_errs = new Array();
            var angle_clicked = new Array();
            var angle_clicked_wrapped = new Array();
            var end_click_times = new Array();
            var judge_response = function(e)  {
                end_click_times.push(performance.now() - start_time);
                var oriClicked = this.getAttribute("oriClicked");
                document.getElementById('oriRing' + oriClicked).
                    removeEventListener('click', judge_response);

                angle_clicked.push(parseInt(oriClicked));
                angle_clicked_wrapped.push(wrap(angle_clicked,180));

                if (trial.which_test == -1) {
                    var err = undefined;
                } else {
                    var err = Math.round(angle_clicked_wrapped)
                        - item_angles[trial.which_test];
                    if (err > 90) { err -= 180; }
                    if (err <= -90) { err += 180; }
                }
                trial_errs.push(err);

                Array.from(document.getElementsByClassName("contMemoryChoice")).forEach(function (e) {
                    e.removeEventListener('click', judge_response);
                });
                if (trial.feedback) {
                    var ringClick1 = document.getElementById('oriRing' + item_angles[trial.which_test]);
                    var ringClick2 = document.getElementById('oriRing' + (item_angles[trial.which_test] + 180));
                    ringClick1.style.border = '4px solid white';
                    ringClick1.style.zIndex = 100;
                    ringClick2.style.border = '4px solid white';
                    ringClick2.style.zIndex = 100;

                    document.getElementById('contMemoryFixation').innerHTML =
                        "You were off by<br>" + Math.abs(err) + " degrees.";
                    setTimeout(endTrial, 1500);
                    
                } else {
                    setTimeout(endTrial, 100);
                }
            };

            /* End trial and record information:
            -------------------------------- */
            var endTrial = () => {
                var trial_data = {
                    "rt": end_click_times,
                    "position_of_items": pos,
                    "item_angles": item_angles,
                    "probe_angle": item_angles[0],
                    "reported_angle": angle_clicked,
                    "trial_error": trial_errs,
                    "which_test": trial.which_test,
                    "probe_pos": pos[0],
                    "set_size": trial.set_size,
                    "retrocue_set_size": trial.retrocue_set_size,
                    "actual_stim_duration": actual_stim_duration,
                    "post_retrocue_delay": trial.post_retrocue_delay
                };
                display_element.innerHTML = '';
                this.jsPsych.finishTrial(trial_data);
            };

        }
    }
    /* Helper functions
     ------------------------------ */

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

            validAngles = this.jsPsych.randomization.repeat(validAngles,1);
            items.push(validAngles[0]);
        }
        return items;
    }

    /* Make sure all numbers in an array are between 0 and 180: */
    function wrap(v,space) {
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
    
    ContinuousOriRetrocuePlugin.info = info;

    return ContinuousOriRetrocuePlugin;
})(jsPsychModule);
