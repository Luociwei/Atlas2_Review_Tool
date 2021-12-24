local Log = require("Matchbox/logging")
func = {}

function func.updateInfo(param, globals, locals, conditions)
    print('Running station common lua function')
    if Device.identifier == "Device_slot1" then
    Device.updateInfo({["failure"]="[A->FA] RBM PGT Test"})
        Device.updateInfo({["failure"]="[A->FA] RBM PGT Test2", ["failure2"]="[A->FA] RBM PGT Test3"})

    end
    return true
end



return func

