#!/bin/lua

local function calculate(input)

    local input_c = input
        :lower()
        :gsub("sqrt", "math.sqrt")
        :gsub("log", "math.log")
        :gsub("sin", "math.sin")
        :gsub("cos", "math.cos")
        :gsub("tan", "math.tan")
        :gsub("pi", "math.pi")
        :gsub("exp", "math.exp")
        :gsub("fmod", "math.fmod")
        :gsub("deg", "math.deg")
        :gsub("rad", "math.rad")
        :gsub("rand", "math.random")

    local calc, err = load("return " .. input_c)

    local out

    if calc and not err then
        out = calc()
    elseif err then
        out = err:match(": (.+)")
    end

    return out
end

print(calculate(arg[1]))
