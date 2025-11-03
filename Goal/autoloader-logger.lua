--configurable logger, currently lives in autoloader but should be in own file for now
-- provides say (basically only used for commands, it's a forced log)
-- info (this is mainly meant to communicate actions that autoloader takes on behalf of the user. like if we downgrade phalanx 2 => pahalnx 1,we'd info that. can be turned off
-- debug (these shoudl be all over the place, to help with debugging).  
-- echo => this is the echo command, sepcial chat area in game. used to show mode switches

--we should tidy up the logs. correct capitalization. dbug logs should show rich info.