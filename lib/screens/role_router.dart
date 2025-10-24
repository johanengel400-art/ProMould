import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'timeline_screen.dart';
import 'daily_input_screen.dart';
import 'issues_screen.dart';
import 'manage_machines_screen.dart';
import 'manage_jobs_screen.dart';
import 'sync_test_screen.dart';

class RoleRouter extends StatefulWidget{
  final int level; final String username;
  const RoleRouter({super.key, required this.level, required this.username});
  @override State<RoleRouter> createState()=>_RoleRouterState();
}

class _RoleRouterState extends State<RoleRouter>{
  int _i=0; late List<Widget> _tabs; late List<NavigationDestination> _dest;

  @override void initState(){
    super.initState();
    final dash = DashboardScreen(username: widget.username, level: widget.level);
    final timeline = TimelineScreen(level: widget.level);
    final inputs = DailyInputScreen(username: widget.username, level: widget.level);
    final issues = IssuesScreen(username: widget.username, level: widget.level);
    final machines = ManageMachinesScreen(level: widget.level);
    final jobs = ManageJobsScreen(level: widget.level);

    if(widget.level==1){
      _tabs=[inputs, timeline, issues];
      _dest=const [
        NavigationDestination(icon: Icon(Icons.edit_note_outlined), label:'Inputs'),
        NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label:'Timeline'),
        NavigationDestination(icon: Icon(Icons.report_problem_outlined), label:'Issues'),
      ];
    } else if(widget.level==2){
      _tabs=[dash, inputs, timeline, issues];
      _dest=const [
        NavigationDestination(icon: Icon(Icons.dashboard_outlined), label:'Dashboard'),
        NavigationDestination(icon: Icon(Icons.edit_note_outlined), label:'Inputs'),
        NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label:'Timeline'),
        NavigationDestination(icon: Icon(Icons.report_problem_outlined), label:'Issues'),
      ];
    } else {
      final syncTest = const SyncTestScreen();
      _tabs=[dash, timeline, inputs, issues, machines, jobs, syncTest];
      _dest=const [
        NavigationDestination(icon: Icon(Icons.dashboard_outlined), label:'Dashboard'),
        NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label:'Timeline'),
        NavigationDestination(icon: Icon(Icons.edit_note_outlined), label:'Inputs'),
        NavigationDestination(icon: Icon(Icons.report_problem_outlined), label:'Issues'),
        NavigationDestination(icon: Icon(Icons.precision_manufacturing_outlined), label:'Machines'),
        NavigationDestination(icon: Icon(Icons.fact_check_outlined), label:'Jobs'),
        NavigationDestination(icon: Icon(Icons.sync_outlined), label:'Sync Test'),
      ];
    }
  }

  @override Widget build(BuildContext context){
    return Scaffold(
      body: SafeArea(child: _tabs[_i]),
      bottomNavigationBar: NavigationBar(
        selectedIndex:_i, onDestinationSelected:(x)=>setState(()=>_i=x), destinations:_dest),
    );
  }
}
