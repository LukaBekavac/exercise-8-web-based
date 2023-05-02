// organization agent

/* Initial beliefs and rules */
org_name("lab_monitoring_org"). // the agent beliefs that it can manage organizations with the id "lab_monitoting_org"
group_name("monitoring_team"). // the agent beliefs that it can manage groups with the id "monitoring_team"
sch_name("monitoring_scheme"). // the agent beliefs that it can manage schemes with the id "monitoring_scheme"

role_goal(R, G) :- role_mission(R, _, M) & mission_goal(M, G).

/* Initial goals */
!start. // the agent has the goal to start

/* 
 * Plan for reacting to the addition of the goal !start
 * Triggering event: addition of goal !start
 * Context: the agent believes that it can manage a group and a scheme in an organization
 * Body: greets the user
*/
@start_plan
+!start : org_name(OrgName) & group_name(GroupName) & sch_name(SchemeName) <-
  !test_wsp;
  .print("Hello world").

/* 
 * Plan for reacting to the addition of the test-goal ?formationStatus(ok)
 * Triggering event: addition of goal ?formationStatus(ok)
 * Context: the agent beliefs that there exists a group G whose formation status is being tested
 * Body: if the belief formationStatus(ok)[artifact_id(G)] is not already in the agents belief base
 * the agent waits until the belief is added in the belief base
*/
@test_formation_status_is_ok_plan
+?formationStatus(ok)[artifact_id(G)] : group(GroupName,_,G)[artifact_id(OrgName)] <-
  .print("Waiting for group ", GroupName," to become well-formed");
  !formGroup;
  .wait({+formationStatus(ok)[artifact_id(G)]}). // waits until the belief is added in the belief base

@form_group_plan
+!formGroup : takenRole(R) <-
    .print("Role filled: ", R);
    .findall(G, (role_goal(Role,G) & R \== Role), L);
    .print("open Goals Remaining: ", L);
    L = [OpenGoal];
    ?role_goal(OpenRole, OpenGoal)
    .print("open Goal ", OpenGoal, OpenRole);
    .broadcast(tell, worktobedone("workspace","lab_monitoring_org", OpenGoal, OpenRole)).


  +!formGroup : true <-
    .wait(1500);
    .print("Looking again for open goals");
    !formGroup.

/* 
 * Plan for reacting to the addition of the goal !inspect(OrganizationalArtifactId)
 * Triggering event: addition of goal !inspect(OrganizationalArtifactId)
 * Context: true (the plan is always applicable)
 * Body: performs an action that launches a console for observing the organizational artifact 
 * identified by OrganizationalArtifactId
*/
@inspect_org_artifacts_plan
+!inspect(OrganizationalArtifactId) : true <-
  // performs an action that launches a console for observing the organizational artifact
  // the action is offered as an operation by the superclass OrgArt (https://moise.sourceforge.net/doc/api/ora4mas/nopl/OrgArt.html)
  debug(inspector_gui(on))[artifact_id(OrganizationalArtifactId)]. 

/* 
 * Plan for reacting to the addition of the belief play(Ag, Role, GroupId)
 * Triggering event: addition of belief play(Ag, Role, GroupId)
 * Context: true (the plan is always applicable)
 * Body: the agent announces that it observed that agent Ag adopted role Role in the group GroupId.
 * The belief is added when a Group Board artifact (https://moise.sourceforge.net/doc/api/ora4mas/nopl/GroupBoard.html)
 * emmits an observable event play(Ag, Role, GroupId)
*/
@play_plan
+play(Ag, Role, GroupId) : true <-
  .print("Agent ", Ag, " accepted the role ", Role, " in group ", GroupId);
  +takenRole(Role).

@test_wsp
+!test_wsp : org_name(OrgName) & group_name(GroupName) & sch_name(SchemeName) <-
// Create and join workspace
println("Creating workspace...");
createWorkspace("workspace");
joinWorkspace("workspace",WspID1);
makeArtifact(OrgName,"ora4mas.nopl.OrgBoard",["src/org/org-spec.xml"],ArtId);
focus(ArtId);
// Create and focus on the Group Board artifact
println("Creating Group Board artifact...");
createGroup(GroupName, monitoring_team, GroupId);
focus(GroupId);
// Create and focus on the Scheme Board artifact
println("Creating Scheme Board artifact...");
createScheme(SchemeName, monitoring_scheme, SchemeId);
focus(SchemeId);
println("Focusing on Scheme Board artifact...");
.broadcast(tell, joinOrg(workspace, OrgName));
.broadcast(tell, new_group("monitoring_team"));
// Wait until the group is well-formed
?formationStatus(ok)[artifact_id(GroupId)];
addScheme(SchemeName)[artifact_id(GroupId)].


/* Import behavior of agents that work in CArtAgO environments */
{ include("$jacamoJar/templates/common-cartago.asl") }

/* Import behavior of agents that work in MOISE organizations */
{ include("$jacamoJar/templates/common-moise.asl") }

/* Import behavior of agents that reason on MOISE organizations */
{ include("$moiseJar/asl/org-rules.asl") }