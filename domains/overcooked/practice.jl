using Gen
using GLMakie

@gen function()
    personality_type = { :ptype } ~ catergorical([.1,.1,.8])
end

@gen function (ptype::Int)
        if ptype == 1
            yell_level = { :ylew} ~ beta(1,5)
        elseif ptype == 2
            
        elseif ptype == 