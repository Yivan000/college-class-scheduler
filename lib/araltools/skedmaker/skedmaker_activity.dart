// Copyright (C) 2023 Tudlang
// 
// This file is part of AralTools.
// 
// AralTools is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// AralTools is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with AralTools.  If not, see <http://www.gnu.org/licenses/>.

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:provider/provider.dart';
import 'package:timetable_view/timetable_view.dart';

import 'classes.dart';
// ignore: unused_import
import 'connection.dart';
import 'functions.dart';
import '/strings.g.dart';
// Here contains hardcoded HTML of the "View course offerrings" table, used for testing
import 'test_tables.dart';

class SkedmakerActivity extends StatefulWidget {
  const SkedmakerActivity({super.key});

  @override
  State<SkedmakerActivity> createState() => _SkedmakerActivityState();
}

class _SkedmakerActivityState extends State<SkedmakerActivity> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SkedmakerModel>(
      create: (context) => SkedmakerModel(),
      child: MultiSplitViewTheme(
        data: MultiSplitViewThemeData(
            dividerPainter: DividerPainters.grooved1(
                backgroundColor: Colors.grey[350],
                color: Colors.indigo[100]!,
                highlightedColor: Colors.indigo[900]!)),
        child: MultiSplitView(
          initialAreas: [Area(weight: 0.3)],
          axis: Axis.horizontal,
          children: [
            MultiSplitView(
              initialAreas: [Area(weight: 0.3)],
              axis: Axis.vertical,
              children: [
                SubjectsFragment(),
                SchedulesFragment(),
              ],
            ),
            TimetableFragment(),
          ],
        ),
      ),
    );
  }
}

class SubjectsFragment extends StatefulWidget {
  const SubjectsFragment({super.key});

  @override
  State<SubjectsFragment> createState() => _SubjectsFragmentState();
}

class _SubjectsFragmentState extends State<SubjectsFragment> {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Text(
                'Subjects (${context.watch<SkedmakerModel>().subjects.length})',
                style: textTheme.headlineSmall,
              ),
              Spacer(),
              OutlinedButton(
                onPressed: () async {

                  // UNCOMMENT TO ADD MLS FUNCTIONALITY
                  final list = await getSubject(context);
                  if (list == null) return;
                  
                  context.read<SkedmakerModel>()
                    // UNCOMMENT TO ADD MLS FUNCTIONALITY
                    ..addSubject(list.first.subject, list)   
                    // THESE ARE FOR DEBUG PURPOSES, hardcoded test HTML tables
                    //..addSubject('CALENG2', parse(caleng2))
                    //..addSubject('LBYMF1C', parse(lbymf1c))
                    //..addSubject('LCLSONE', parse(lclsone))
                    //..addSubject('LBYMF1D', parse(lbymf1d))
                    ;
                },
                child: Text('Add'),
              ),
              // TODO add more options
              //PopupMenuButton(
              //  itemBuilder: (context) => [PopupMenuItem(child: Text('asd'))],
              //)
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: context.watch<SkedmakerModel>().subjects.length,
            itemBuilder: (context, index) {
              bool isHovered = false;
              final current = context
                  .read<SkedmakerModel>()
                  .subjects
                  .entries
                  .elementAt(index);
              return StatefulBuilder(builder: (context, setState) {
                return MouseRegion(
                  onEnter: (event) {
                    setState(() {
                      isHovered = true;
                    });
                  },
                  onExit: (event) {
                    setState(() {
                      isHovered = false;
                    });
                  },
                  child: ListTile(
                    title: Text(current.key),
                    dense: true,
                    subtitle:
                        Text(current.value.length.toString() + ' offerings'),
                    trailing: !isHovered ||
                            context.read<SkedmakerModel>().isGenerating
                        ? null
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // TODO ADD EDIT BUTTON with dialog
                              //IconButton(
                              //    tooltip: 'Edit',
                              //    onPressed: () {},
                              //    icon: Icon(Icons.edit)),
                              IconButton(
                                  tooltip: strings.general.general.delete,
                                  onPressed: () async {
                                    final hasSchedules = context
                                        .read<SkedmakerModel>()
                                        .schedules
                                        .isEmpty;

                                    var shouldAlsoDeleteSchedules = false;
                                    final shouldDelete = await showDialog<bool>(
                                      context: context,
                                      builder: (context) {
                                        return StatefulBuilder(
                                            builder: (context, setState) {
                                          return AlertDialog(
                                            title:
                                                Text('Delete ${current.key}?'),
                                            content: hasSchedules
                                                ? null
                                                : CheckboxListTile(
                                                    controlAffinity:
                                                        ListTileControlAffinity
                                                            .leading,
                                                    value:
                                                        shouldAlsoDeleteSchedules,
                                                    title: Text(
                                                        'Also delete generated schedules'),
                                                    onChanged: (value) {
                                                      setState(() {
                                                        shouldAlsoDeleteSchedules =
                                                            !shouldAlsoDeleteSchedules;
                                                      });
                                                    },
                                                  ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                child: Text(strings
                                                    .general.general.cancel),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context, true);
                                                },
                                                child: Text(strings
                                                    .general.general.delete),
                                              ),
                                            ],
                                          );
                                        });
                                      },
                                    );
                                    if (shouldDelete == true) {
                                      context
                                          .read<SkedmakerModel>()
                                          .removeSubject(current.key);
                                      if (shouldAlsoDeleteSchedules) {
                                        context.read<SkedmakerModel>()
                                          ..schedules = {}
                                          ..schedulesSelected = null;
                                      }
                                    }
                                  },
                                  icon: Icon(Icons.delete))
                            ],
                          ),
                  ),
                );
              });
            },
          ),
        ),
      ],
    );
  }
}

class SchedulesFragment extends StatefulWidget {
  const SchedulesFragment({super.key});

  @override
  State<SchedulesFragment> createState() => _SchedulesFragmentState();
}

class _SchedulesFragmentState extends State<SchedulesFragment> {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    var i = 0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Text(
                'Possible schedules (${context.watch<SkedmakerModel>().schedules.length})',
                style: textTheme.headlineSmall,
              ),
              Spacer(),
              if (context.watch<SkedmakerModel>().subjects.isNotEmpty &&
                  !context.watch<SkedmakerModel>().isGenerating)
                OutlinedButton(
                  onPressed: () {
                    // Generates possible schedules

                    context.read<SkedmakerModel>()
                      ..schedules = {}
                      ..isGenerating = true;

                    final subjects = context.read<SkedmakerModel>().subjects;

                    // count execution time
                    final stopwatch = Stopwatch()..start();

                    generageSchedules([for (final i in subjects.values) ...i],
                            subjects.keys.toSet())
                        .listen((event) {
                      final model = context.read<SkedmakerModel>();
                      if (!model.schedules.contains(event)) {
                        model.addSchedule(event);
                      }
                    }).onDone(() {
                      stopwatch.stop();
                      print("ELAPSED TIME: ${stopwatch.elapsedMilliseconds}");

                      context.read<SkedmakerModel>().isGenerating = false;
                    });
                  },
                  child: Text('Generate'),
                )
            ],
          ),
        ),
        if (context.watch<SkedmakerModel>().isGenerating)
          LinearProgressIndicator(),
        Expanded(
          child: SingleChildScrollView(
            // TODO add tabs on the TimetableFragment so that we can view multiple scheds
            child: DataTable(
              headingRowHeight: 30,
              dataRowHeight: 36,
              columns: [
                DataColumn(label: Text(strings.skedmaker.schedules.table.name)),
                DataColumn(label: Text(strings.skedmaker.schedules.table.days)),
                DataColumn(
                    label: Text(strings.skedmaker.schedules.table.weight),
                    numeric: true),
              ],
              rows: [
                for (final schedule
                    in context.watch<SkedmakerModel>().schedules)
                  DataRow(
                    selected:
                        context.watch<SkedmakerModel>().schedulesSelected ==
                            schedule,
                    cells: [
                      DataCell(
                        Text(schedule.name.isEmpty
                            ? 'Schedule ${++i}'
                            : schedule.name),
                      ),
                      DataCell(Text(schedule.identifierString)),
                      DataCell(Text(schedule.weight.round().toString()))
                    ],
                    onSelectChanged: (isSelected) {
                      context.read<SkedmakerModel>().schedulesSelected =
                          schedule;
                    },
                  )
              ],
            ),
          ),
          /*
          child: ListView.builder(
            itemCount: context.watch<SkedmakerModel>().schedules.length,
            itemBuilder: (context, index) {
              final current =
                  context.read<SkedmakerModel>().schedules.elementAt(index);
              return ListTile(
                selected: context.watch<SkedmakerModel>().schedulesSelected ==
                    current,
                title: Text("${current.name.isEmpty ? 'Schedule $index' : current.name} ${current.identifierString}"),
                dense: true,
                leading: Text((index + 1).toString()),
                onTap: () {
                  context.read<SkedmakerModel>().schedulesSelected = current;
                },
              );
            },
          ),*/
        ),
      ],
    );
  }
}

class TimetableFragment extends StatefulWidget {
  const TimetableFragment({super.key, this.data});
  final ScheduleWeek? data;

  @override
  State<TimetableFragment> createState() => _TimetableFragmentState();
}

class _TimetableFragmentState extends State<TimetableFragment> {
  @override
  Widget build(BuildContext context) {
    var data = widget.data ?? context.watch<SkedmakerModel>().schedulesSelected;

    if (data == null) return Container();

    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Timetable for ${data.name}',
                style: textTheme.headlineSmall,
              ),
            ),
          ],
        ),
        Expanded(
            child: TimetableView(
          timetableStyle: TimetableStyle(
            laneWidth: 150,
            timeItemHeight: 50,
            startHour: 7,
            endHour: 20,
          ),
          laneEventsList: [
            for (final day in ScheduleWeek.daycodes)
              LaneEvents(
                  lane: Lane(name: day, laneIndex: 1),
                  events: data
                      .from(day)
                      .map((e) => TableEvent(
                          location: "${e.scheduleDay.daycode} ${e.room}\n",
                          title: "${e.subject} - ${e.section} \n",
                          eventId: e.classNumber,
                          laneIndex: 1,
                          startTime: t(e.scheduleTimeStart),
                          endTime: t(e.scheduleTimeEnd)))
                      .toList())
          ],
          onEmptySlotTap: (laneIndex, start, end) {},
          onEventTap: (event) {},
        )),
      ],
    );
  }

  ///converts 24hour time format to a [TableEventTime]
  TableEventTime t(int time24) => TableEventTime(
      hour: (time24 / 100).floor(),
      minute: int.parse("${(time24 / 10).floor() % 10}${time24 % 10}"));
}

class SkedmakerModel extends ChangeNotifier {
  Map<String, List<Offering>> subjects;
  Set<ScheduleWeek> _schedules;
  ScheduleWeek? _schedulesSelected;

  void addSubject(String code, List<Offering> list) {
    subjects[code] = list;
    notifyListeners();
  }

  void removeSubject(String code) {
    subjects.remove(code);
    notifyListeners();
  }

  set schedules(Set<ScheduleWeek> a) {
    _schedules = a;
    _schedulesSelected = null;
    notifyListeners();
  }

  Set<ScheduleWeek> get schedules => _schedules;

  void addSchedule(ScheduleWeek a) {
    // the [none] function is used since [!contains] doesn't actually filter out duplicates
    if (_schedules.none((element) => element == a)) _schedules.add(a);
    notifyListeners();
  }

  set schedulesSelected(ScheduleWeek? a) {
    _schedulesSelected = a;
    notifyListeners();
  }

  ScheduleWeek? get schedulesSelected => _schedulesSelected;

  bool _isGenerating = false;
  set isGenerating(bool a) {
    _isGenerating = a;
    notifyListeners();
  }

  bool get isGenerating => _isGenerating;

  SkedmakerModel()
      : subjects = {},
        _schedules = {};
}
