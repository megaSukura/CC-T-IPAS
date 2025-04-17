_G.BASALT_PATH = "/lib/BasaltMaster/init"
_G.LibRequire = function (path)
    return require("lib/" .. path)
    
end
_G.BASALT = function ()
    return require(BASALT_PATH)
end
_G.print_table = require("lib/print_r")
_G.BPrintTable = function (basalt,table,filter)
    print_table(table,basalt.debug,filter)
    
end