var jsPsychImageDistractResponse = (function (jspsych) {
    'use strict';

    const info = {
        name: "image-keyboard-response",
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
            /** Duration to display each image. */
            frame_time: {
                type: jspsych.ParameterType.INT,
                pretty_name: "Frame time",
                default: 250,
            },
            /** Length of gap to be shown between each image. */
            frame_isi: {
                type: jspsych.ParameterType.INT,
                pretty_name: "Frame gap",
                default: 0,
            },
             /** Number of times to show entire sequence */
            sequence_reps: {
            type: jspsych.ParameterType.INT,
            pretty_name: "Sequence repetitions",
            default: 1,
             },
            /** Array containing the key(s) the subject is allowed to press to respond to the stimulus. */
            choices: {
                type: jspsych.ParameterType.KEYS,
                pretty_name: "Choices",
                default: "ALL_KEYS",
            },
            /** Any content here will be displayed below the stimulus. */
            prompt: {
                type: jspsych.ParameterType.HTML_STRING,
                pretty_name: "Prompt",
                default: null,
            },
            /** How long to show the stimulus. */
            stimulus_duration: {
                type: jspsych.ParameterType.INT,
                pretty_name: "Stimulus duration",
                default: null,
            },
            /** How long to show trial before it ends */
            trial_duration: {
                type: jspsych.ParameterType.INT,
                pretty_name: "Trial duration",
                default: null,
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
            /** HK stuff below */
            // image params
            target_angles: { //angle to display target image
                type: jsPsych.ParameterType.INT,
                pretty_name: 'Actual oris to show (optional)',
                default: [],
                array: true,
                description: 'If not empty, should be a list of oris to show, in degrees, of same length as set_size. If empty, random oris with min distance between them of min_difference [option below] will be chosen. '
            },
            target_kappa: { //which target image kappa 
                type: jsPsych.ParameterType.INT,
                pretty_name: 'Actual kappa to show (necessary)',
                default: [],
                description: 'If not empty, should select kappa for image for target presentation. '
            },
            distractor_cond: { //what type of distractor. 1 = none 2 = present 3 = wiggle
                type: jsPsych.ParameterType.INT,
                pretty_name: 'Actual distractor condition to show (necessary)',
                default: [],
                description: 'If not empty, should select image for delay presentation. '
            },
            min_difference: { //make sure target, distractor, and probe angles are different in a trial
                type: jsPsych.ParameterType.INT,
                pretty_name: 'Min difference between different items',
                default: 15,
                description: 'Min difference between items in degrees of ori space (to reduce grouping).'
            },
            bg_color: { //mid gray for screen
                type: jsPsych.ParameterType.STRING,
                pretty_name: 'BG color of box for experiment',
                default: '#848484', /* should match BG of targets */
                description: 'BG color of box for experiment.'
            }
        },
    };
    /**
     * **image-keyboard-response**
     *
     * jsPsych plugin for displaying an image stimulus and getting a keyboard response
     *
     * @author Josh de Leeuw
     * @see {@link https://www.jspsych.org/plugins/jspsych-image-keyboard-response/ image-keyboard-response plugin documentation on jspsych.org}
     * modified by Holly Kular July 2023 for WM_Dist_V10 */
    class ImageDistractResponsePlugin {
        constructor(jsPsych) {
            this.jsPsych = jsPsych;
        }
        trial(display_element, trial) {
            /* Add CSS for classes just once when
            plugin is first used:
            --------------------------------*/
            if (!css_added) {
                var css = `
            .imageDisplay {
            position: absolute;
            transform-origin: center;
            background: '';
            z-index = -1;}
                
            .responseDisplay {
            width: 20px;
            height: 20px;
            border-radius: 50%;
            cursor: pointer;
            font-size: 10pt;
            display: flex;
            align-items: center;
            justify-content: center;
            z-index = -1;}

            #DisplayBox {
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

            var interval_time = trial.frame_time + trial.frame_isi;
            var animate_frame = 0;
            var reps = 0;
            var startTime = performance.now();
            var animation_sequence = [];
            var responses = [];
            var current_stim = "";
            var height, width;
            if (trial.render_on_canvas) {
                var image_drawn = false;
                // first clear the display element (because the render_on_canvas method appends to display_element instead of overwriting it with .innerHTML)
                if (display_element.hasChildNodes()) {
                    // can't loop through child list because the list will be modified by .removeChild()
                    while (display_element.firstChild) {
                        display_element.removeChild(display_element.firstChild);
                    }
                }
                // create canvas element and image
                var canvas = document.createElement("canvas");
                canvas.id = "jspsych-animation-image";
                canvas.style.margin = "0";
                canvas.style.padding = "0";
                canvas.style.cursor = 'none'; //maybe ?? could annoy people
                display_element.insertBefore(canvas, null); //maybe ??
                var ctx = canvas.getContext("2d");
                var img = new Image();
                img.onload = () => {
                    // if image wasn't preloaded, then it will need to be drawn whenever it finishes loading
                    if (!image_drawn) {
                        getHeightWidth(); // only possible to get width/height after image loads
                        ctx.drawImage(img, 0, 0, width, height);
                    }
                };

                //preload images for each trial
                // old code img.src = trial.stimulus;
                // load targets phase 1 and 2 randomly from 1 through 500
                var targets = [];
                var numberOfTargets = 2;
                var minNumber = 1;
                var maxNumber = 500;
                for (var i = 0; i < numberOfTargets; i++) {
                    var randomTarget = Math.floor(Math.random() * (maxNumber - minNumber + 1)) + minNumber;
                    var Target1Path = 'images/targets/Target_k' + trial.kappa + 'p1n' + randomTarget + '.png';
                    var Target2Path = 'images/targets/Target_k' + trial.kappa + 'p2n' + randomTarget + '.png';
                    targets.push(Target1Path, Target2Path);
                }
                // load distractors 10 randomly from 1 through 500
                var distractors = [];
                var numberOfDistractors = 10;
                if (trial.distractor === 2 || trial.distractor === 3) {
                    for (var i = 0; i < numberOfDistractors; i++) {
                        var randomDistractor = Math.floor(Math.random() * (maxNumber - minNumber + 1)) + minNumber;
                        var distractorPath = 'images/distractors/distractor_n' + randomDistractor + '.png';
                        distractors.push(distractorPath);
                    }
                }
                img.src = targets[0]; // for now just target1 -- maybe this needs to be a for loop to draw each one?
                // get/set image height and width - this can only be done after image loads because uses image's naturalWidth/naturalHeight properties
                const getHeightWidth = () => {
                    if (trial.stimulus_height !== null) {
                        height = trial.stimulus_height;
                        if (trial.stimulus_width == null && trial.maintain_aspect_ratio) {
                            width = img.naturalWidth * (trial.stimulus_height / img.naturalHeight);
                        }
                    }
                    else {
                        height = img.naturalHeight;
                    }
                    if (trial.stimulus_width !== null) {
                        width = trial.stimulus_width;
                        if (trial.stimulus_height == null && trial.maintain_aspect_ratio) {
                            height = img.naturalHeight * (trial.stimulus_width / img.naturalWidth);
                        }
                    }
                    else if (!(trial.stimulus_height !== null && trial.maintain_aspect_ratio)) {
                        // if stimulus width is null, only use the image's natural width if the width value wasn't set
                        // in the if statement above, based on a specified height and maintain_aspect_ratio = true
                        width = img.naturalWidth;
                    }
                    canvas.height = height;
                    canvas.width = width;
                };
                getHeightWidth(); // call now, in case image loads immediately (is cached)
                // add canvas and draw image
                display_element.insertBefore(canvas, null);
                if (img.complete && Number.isFinite(width) && Number.isFinite(height)) {
                    // if image has loaded and width/height have been set, then draw it now
                    // (don't rely on img onload function to draw image when image is in the cache, because that causes a delay in the image presentation)
                    ctx.drawImage(img, 0, 0, width, height);
                    image_drawn = true;
                }
                // add prompt if there is one
                if (trial.prompt !== null) {
                    display_element.insertAdjacentHTML("beforeend", trial.prompt);
                }

                const endTrial = () => {
                    this.jsPsych.pluginAPI.cancelKeyboardResponse(response_listener);
                    var trial_data = {
                        animation_sequence: animation_sequence,
                        response: responses,
                    };
                    this.jsPsych.finishTrial(trial_data);
                }; 

            
                var animate_interval = setInterval(() => {
                    var showImage = true;
                    if (!trial.render_on_canvas) {
                        display_element.innerHTML = ""; // clear everything
                    }
                    animate_frame++;
                    if (animate_frame == stimulus.length) {
                        animate_frame = 0;
                        reps++;
                        if (reps >= trial.sequence_reps) {
                            endTrial();
                            clearInterval(animate_interval);
                            showImage = false;
                        }
                    }
                    if (showImage) {
                        show_next_frame();
                    }
                }, interval_time);

                const show_next_frame = () => {
                    if (trial.render_on_canvas) {
                        display_element.querySelector("#jspsych-animation-image").style.visibility =
                            "visible";
                        var img = new Image();
                        img.src = targets[animate_frame];
                        //canvas.height = img.naturalHeight;
                        //canvas.width = img.naturalWidth;
                        ctx.drawImage(img, 0, 0);
                        if (trial.prompt !== null && animate_frame == 0 && reps == 0) {
                            display_element.insertAdjacentHTML("beforeend", trial.prompt);
                        }
                    }
                    else {
                        // show image
                        display_element.innerHTML =
                            '<img src="' + trial.stimuli[animate_frame] + '" id="jspsych-animation-image"></img>';
                        if (trial.prompt !== null) {
                            display_element.innerHTML += trial.prompt;
                        }
                    }
                    current_stim = trial.stimuli[animate_frame];
                    // record when image was shown
                    animation_sequence.push({
                        stimulus: trial.stimuli[animate_frame],
                        time: Math.round(performance.now() - startTime),
                    });
                    if (trial.frame_isi > 0) {
                        this.jsPsych.pluginAPI.setTimeout(() => {
                            display_element.querySelector("#jspsych-animation-image").style.visibility =
                                "hidden";
                            current_stim = "blank";
                            // record when blank image was shown
                            animation_sequence.push({
                                stimulus: "blank",
                                time: Math.round(performance.now() - startTime),
                            });
                        }, trial.frame_time);
                    }
                };

            }
            /* not using this because will be drawing as a canvas element only
            else {
                // display stimulus as an image element
                var html = '<img src="' + trial.stimulus + '" id="jspsych-image-distract-response-stimulus">';
                // add prompt
                if (trial.prompt !== null) {
                    html += trial.prompt;
                }
                // update the page content
                display_element.innerHTML = html;
                // set image dimensions after image has loaded (so that we have access to naturalHeight/naturalWidth)
                var img = display_element.querySelector("#jspsych-image-distract-response-stimulus");
                if (trial.stimulus_height !== null) {
                    height = trial.stimulus_height;
                    if (trial.stimulus_width == null && trial.maintain_aspect_ratio) {
                        width = img.naturalWidth * (trial.stimulus_height / img.naturalHeight);
                    }
                }
                else {
                    height = img.naturalHeight;
                }
                if (trial.stimulus_width !== null) {
                    width = trial.stimulus_width;
                    if (trial.stimulus_height == null && trial.maintain_aspect_ratio) {
                        height = img.naturalHeight * (trial.stimulus_width / img.naturalWidth);
                    }
                }
                else if (!(trial.stimulus_height !== null && trial.maintain_aspect_ratio)) {
                    // if stimulus width is null, only use the image's natural width if the width value wasn't set
                    // in the if statement above, based on a specified height and maintain_aspect_ratio = true
                    width = img.naturalWidth;
                }
                img.style.height = height.toString() + "px";
                img.style.width = width.toString() + "px";
            }*/
            // store response
            var response = {
                rt: null,
                key: null,
            };
            // function to end trial when it is time
            const end_trial = () => {
                // kill any remaining setTimeout handlers
                this.jsPsych.pluginAPI.clearAllTimeouts();
                // kill keyboard listeners
                if (typeof keyboardListener !== "undefined") {
                    this.jsPsych.pluginAPI.cancelKeyboardResponse(keyboardListener);
                }
                // gather the data to store for the trial
                var trial_data = {
                    rt: response.rt,
                    stimulus: trial.stimulus,
                    response: response.key,
                };
                // clear the display
                display_element.innerHTML = "";
                // move on to the next trial
                this.jsPsych.finishTrial(trial_data);
            };
            // function to handle responses by the subject
            var after_response = (info) => {
                // after a valid response, the stimulus will have the CSS class 'responded'
                // which can be used to provide visual feedback that a response was recorded
                display_element.querySelector("#jspsych-image-distract-response-stimulus").className +=
                    " responded";
                // only record the first response
                if (response.key == null) {
                    response = info;
                }
                if (trial.response_ends_trial) {
                    end_trial();
                }
            };
            // start the response listener
            if (trial.choices != "NO_KEYS") {
                var keyboardListener = this.jsPsych.pluginAPI.getKeyboardResponse({
                    callback_function: after_response,
                    valid_responses: trial.choices,
                    rt_method: "performance",
                    persist: false,
                    allow_held_key: false,
                });
            }
            // hide stimulus if stimulus_duration is set
            if (trial.stimulus_duration !== null) {
                this.jsPsych.pluginAPI.setTimeout(() => {
                    display_element.querySelector("#jspsych-image-distract-response-stimulus").style.visibility = "hidden";
                }, trial.stimulus_duration);
            }
            // end trial if trial_duration is set
            if (trial.trial_duration !== null) {
                this.jsPsych.pluginAPI.setTimeout(() => {
                    end_trial();
                }, trial.trial_duration);
            }
            else if (trial.response_ends_trial === false) {
                console.warn("The experiment may be deadlocked. Try setting a trial duration or set response_ends_trial to true.");
            }
        }
        simulate(trial, simulation_mode, simulation_options, load_callback) {
            if (simulation_mode == "data-only") {
                load_callback();
                this.simulate_data_only(trial, simulation_options);
            }
            if (simulation_mode == "visual") {
                this.simulate_visual(trial, simulation_options, load_callback);
            }
        }
        simulate_data_only(trial, simulation_options) {
            const data = this.create_simulation_data(trial, simulation_options);
            this.jsPsych.finishTrial(data);
        }
        simulate_visual(trial, simulation_options, load_callback) {
            const data = this.create_simulation_data(trial, simulation_options);
            const display_element = this.jsPsych.getDisplayElement();
            this.trial(display_element, trial);
            load_callback();
            if (data.rt !== null) {
                this.jsPsych.pluginAPI.pressKey(data.response, data.rt);
            }
        }
        create_simulation_data(trial, simulation_options) {
            const default_data = {
                stimulus: trial.stimulus,
                rt: this.jsPsych.randomization.sampleExGaussian(500, 50, 1 / 150, true),
                response: this.jsPsych.pluginAPI.getValidKey(trial.choices),
            };
            const data = this.jsPsych.pluginAPI.mergeSimulationData(default_data, simulation_options);
            this.jsPsych.pluginAPI.ensureSimulationDataConsistency(trial, data);
            return data;
        }
    }
    ImageDistractResponsePlugin.info = info;

    return ImageDistractResponsePlugin;

})(jsPsychModule);