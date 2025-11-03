--Responsible for understanding autoloader's predefined set names, and using codex's information to build ordered sets for a given spell/action.
--ex: autoloader calls resolver to find out what sets are needed for the player's cast of "Fire III" in magic mode: macc. 
-- autoloader then calls autoloader-sets with the reelvant set names from resolver,
autoloader-sets uses the set names, combines them in appropriate order and returns a set 
-- autoloader then equips the set.

-a lot of the code in codex should be moving here.
-codex will only know about the details/stat mappings of ffxi spells and abilities, and how to parse items.
--it shouldn't know anything about autoloader sets