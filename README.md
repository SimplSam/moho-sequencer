# moho-sequencer
A simple Moho tool script to view & update a Layers sequence timing offset - relative to the project start frame.

### Version ###

*	version: MH12/13 001.0 #510124.01      -- by Sam Cogheil (SimplSam)
*	release: n/a

### How do I get set up ? ###

* To install:

  - Save the 'ss_sequencer.lua' and 'ss_sequencer.png' file/s to your computer into your custom scripts/tools folder
  - Reload Moho/AnimeStudio scripts (or Restart Moho)

* To use:

  - Select a layer
  - Run the tool from the Tools palette
  - A popup panel will appear allowing you to Review and adjust the layers start frame / offset position

  - notes:
    - Any changes made are dynamic and in realtime. You will be able to see the effect of those changes in the timeline & viewport. Use the __Cancel__ button to UNDO any changes. __OK__ will confirm them
    - You can either set the Relative sequence offset -or- Absolute start frame, and the other value will be adjusted accordingly
    - The relative offset is relative to the Document start frame, and any additional offset already present in the Parent group/s

* options:
  - none
