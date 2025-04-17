local telem = require 'telem'
local backplane = telem.backplane()
	:addInput('my_securemodem', telem.input.secureModem('top', 'M-msNHZBcVU_p7mrXc0sgmFa3ms7vpDxQD8HnMq3pHo='))
    :addOutput("my_out_holl",telem.output.helloWorld())

    parallel.waitForAny(
        backplane:cycleEvery(3)
    )