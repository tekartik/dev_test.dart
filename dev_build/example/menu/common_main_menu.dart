library;

import 'package:dev_build/menu/menu_io.dart';

void main(List<String> arguments) {
  mainMenuConsole(arguments, () {
    commonMainMenu();
  });
}

void commonMainMenu() {
  menu('main', () {
    item('write hola', () async {
      write('Hola');
    });
    item('write lorem lipsum', () async {
      write(
          'Sed gravida iaculis lectus, vel suscipit turpis malesuada sit amet. In maximus rutrum libero, eu porta nulla vehicula eu. Donec vel dictum neque, vitae aliquet velit. Fusce nec orci non diam dignissim tristique non sed est. Quisque venenatis a orci et venenatis.\n'
          'Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos.');
    });
    item('prompt', () async {
      write('RESULT prompt: ${await prompt()}');
    });
    item('print hi', () {
      // ignore: avoid_print
      print('hi');
    });
    item('crash', () {
      throw 'crash';
    });
    menu('sub', () {
      menu('below', () {
        item('write below', () => write('below sub'));
      });
      item('write sub', () => write('sub'));
    });
    item('write 250 lines', () {
      for (var i = 1; i <= 250; i++) {
        write('$i: this is a line, but only 100 of them will be displayed');
      }
    });

    menu('slow_sub', () {
      enter(() async {
        write('enter sub');
        await Future<void>.delayed(const Duration(milliseconds: 1000));
        write('enter sub done');
      });
      leave(() async {
        write('leave sub');
        await Future<void>.delayed(const Duration(milliseconds: 1000));
        write('leave sub done');
      });
      item('write hi', () {
        write('hi from slow_sub');
      });
    });
  });
}
