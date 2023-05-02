// sensing agent


/* Initial beliefs and rules */

role_goal(R, G) :- role_mission(R, _, M) & mission_goal(M, G).
can_achieve(G) :- .relevant_plans({+!G[scheme(_)]}, LP) & LP \== [].
i_have_plans_for(R) :- not (role_goal(R, G) & not can_achieve(G)).

/* Initial goals */
!start. // the agent has the goal to start

/* 
 * Plan for reacting to the addition of the goal !start
 * Triggering event: addition of goal !start
 * Context: the agent believes that it can manage a group and a scheme in an organization
 * Body: greets the user
*/
@start_plan
+!start : true <-
	.print("Hello world").

/* 
 * Plan for reacting to the addition of the goal !read_temperature
 * Triggering event: addition of goal !read_temperature
 * Context: true (the plan is always applicable)
 * Body: reads the temperature using a weather station artifact and broadcasts the reading
*/
@read_temperature_plan
+!read_temperature : true <-
	.print("I will read the temperature");
	makeArtifact("weatherStation", "tools.WeatherStation", [], WeatherStationId); // creates a weather station artifact
	focus(WeatherStationId); // focuses on the weather station artifact
	readCurrentTemperature(43.50, 16.44, Celcius); // reads the current temperature using the artifact
	.print("Temperature Reading (Celcius): ", Celcius);
	.broadcast(tell, temperature(Celcius)). // broadcasts the temperature reading

@join_plan
+joinOrg(WspName, OrgName): true <-
    joinWorkspace(WspName, WspID1);
    lookupArtifact(OrgName, ArtId);
    focus(ArtId);
    !focusing;
    !accept;
    .print("I joined the organization ", OrgName).

@focus_plan
+!focusing : group(GroupName, _, _) & scheme(SchemeName, _, _) <-
	lookupArtifact(GroupName, GroupId);
	focus(GroupId);
	lookupArtifact(SchemeName, SchemeId);
	focus(SchemeId).

@accept_role_plan
+!accept : role_goal(R, G) & can_achieve(G) <-
	 adoptRole(R);
	.print("accepted role ", R).




/* Import behavior of agents that work in CArtAgO environments */
{ include("$jacamoJar/templates/common-cartago.asl") }

/* Import behavior of agents that work in MOISE organizations */
{ include("$jacamoJar/templates/common-moise.asl") }

/* Import behavior of agents that reason on MOISE organizations */
{ include("$moiseJar/asl/org-rules.asl") }

/* Import behavior of agents that react to organizational events
(if observing, i.e. being focused on the appropriate organization artifacts) */
{ include("inc/skills.asl") }