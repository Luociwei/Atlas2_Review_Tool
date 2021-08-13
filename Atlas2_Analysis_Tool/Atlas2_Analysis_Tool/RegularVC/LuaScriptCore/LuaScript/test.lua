function LSCTPerson.prototype:destroy ()

    print("LSCTPerson destroy");

end

local person = LSCTPerson();
person.name = "vimfung";
person:walk();
person:speak();
print(person.name)
LSCTPerson:testlog()
LSCTPerson:testlog("sssssss33")
person:create("louis","ss")

