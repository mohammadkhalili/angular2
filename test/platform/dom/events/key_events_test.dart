@Tags(const ['codegen'])
@TestOn('browser')
library angular2.test.platform.dom.events.key_events;

import 'dart:html';
import 'dart:js';

import 'package:angular2/angular2.dart';
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

void main() {
  tearDown(disposeAnyRunningTest);

  test("Should receive 'keydown' event", () async {
    var testBed = new NgTestBed<KeydownListenerComponent>();
    var testFixture = await testBed.create();
    var event = new KeyboardEvent('keydown');
    testFixture.rootElement.dispatchEvent(event);
    await testFixture.update((component) {
      expect(component.receivedKeydown, isTrue);
      expect(component.receivedKeydownA, isFalse);
      expect(component.receivedKeydownShiftA, isFalse);
    });
  });

  test("Should receive 'keydown.a' event", () async {
    var testBed = new NgTestBed<KeydownListenerComponent>();
    var testFixture = await testBed.create();
    var event = createKeyboardEvent('keydown', KeyCode.A);
    testFixture.rootElement.dispatchEvent(event);
    await testFixture.update((component) {
      expect(component.receivedKeydown, isTrue);
      expect(component.receivedKeydownA, isTrue);
      expect(component.receivedKeydownShiftA, isFalse);
    });
  });

  test("Should receive 'keydown.shift.a", () async {
    var testBed = new NgTestBed<KeydownListenerComponent>();
    var testFixture = await testBed.create();
    var event = createKeyboardEvent('keydown', KeyCode.A, shiftKey: true);
    testFixture.rootElement.dispatchEvent(event);
    await testFixture.update((component) {
      expect(component.receivedKeydown, isTrue);
      expect(component.receivedKeydownA, isFalse);
      expect(component.receivedKeydownShiftA, isTrue);
    });
  });

  test("Should receive 'keypress' event", () async {
    var testBed = new NgTestBed<KeypressListenerComponent>();
    var testFixture = await testBed.create();
    var event = new KeyboardEvent('keypress');
    testFixture.rootElement.dispatchEvent(event);
    await testFixture.update((component) {
      expect(component.receivedKeypress, isTrue);
    });
  });

  test("Should receive 'keyup' event", () async {
    var testBed = new NgTestBed<KeyupListenerComponent>();
    var testFixture = await testBed.create();
    var event = new KeyboardEvent('keyup');
    testFixture.rootElement.dispatchEvent(event);
    await testFixture.update((component) {
      expect(component.receivedKeyup, isTrue);
      expect(component.receivedKeyupEnter, isFalse);
      expect(component.receivedKeyupCtrlEnter, isFalse);
    });
  });

  test("Should receive 'keyup.enter' event", () async {
    var testBed = new NgTestBed<KeyupListenerComponent>();
    var testFixture = await testBed.create();
    var event = createKeyboardEvent('keyup', KeyCode.ENTER);
    testFixture.rootElement.dispatchEvent(event);
    await testFixture.update((component) {
      expect(component.receivedKeyup, isTrue);
      expect(component.receivedKeyupEnter, isTrue);
      expect(component.receivedKeyupCtrlEnter, isFalse);
    });
  });

  test("Should receive 'keyup.control.enter' event", () async {
    var testBed = new NgTestBed<KeyupListenerComponent>();
    var testFixture = await testBed.create();
    var event = createKeyboardEvent('keyup', KeyCode.ENTER, ctrlKey: true);
    testFixture.rootElement.dispatchEvent(event);
    await testFixture.update((component) {
      expect(component.receivedKeyup, isTrue);
      expect(component.receivedKeyupEnter, isFalse);
      expect(component.receivedKeyupCtrlEnter, isTrue);
    });
  });

  test("Should receive keyboard event with multiple modifiers", () async {
    var testBed = new NgTestBed<ModifiersListener>();
    var testFixture = await testBed.create();
    var event = createKeyboardEvent('keyup', KeyCode.NUM_ZERO,
        altKey: true, metaKey: true);
    testFixture.rootElement.dispatchEvent(event);
    await testFixture.update((component) {
      expect(component.receivedModifiers, isTrue);
    });
  });
}

@Component(selector: 'keydown-listener', host: const {
  '(keydown)': 'receivedKeydown = true',
  '(keydown.a)': 'receivedKeydownA = true',
  '(keydown.shift.a)': 'receivedKeydownShiftA = true',
})
class KeydownListenerComponent {
  bool receivedKeydown = false;
  bool receivedKeydownA = false;
  bool receivedKeydownShiftA = false;
}

@Component(selector: 'keypress-listener', host: const {
  '(keypress)': 'receivedKeypress = true',
})
class KeypressListenerComponent {
  bool receivedKeypress = false;
}

@Component(selector: 'keyup-listener', host: const {
  '(keyup)': 'receivedKeyup = true',
  '(keyup.enter)': 'receivedKeyupEnter = true',
  '(keyup.control.enter)': 'receivedKeyupCtrlEnter = true',
})
class KeyupListenerComponent {
  bool receivedKeyup = false;
  bool receivedKeyupEnter = false;
  bool receivedKeyupCtrlEnter = false;
}

@Component(selector: 'modifiers-listener', host: const {
  '(keyup.alt.meta.0)': 'receivedModifiers = true',
})
class ModifiersListener {
  bool receivedModifiers = false;
}

const CREATE_KEYBOARD_EVENT_NAME = '__dart_createKeyboardEvent';
const CREATE_KEYBOARD_EVENT_SCRIPT = '''
window['$CREATE_KEYBOARD_EVENT_NAME'] = function(
    type, keyCode, ctrlKey, altKey, shiftKey, metaKey) {
  var event = document.createEvent('KeyboardEvent');

  // Chromium hack.
  Object.defineProperty(event, 'keyCode', {
    get: function() { return keyCode; }
  });

  // Creating keyboard events programmatically isn't supported and relies on
  // these deprecated APIs.
  if (event.initKeyboardEvent) {
    event.initKeyboardEvent(type, true, true, document.defaultView, keyCode,
        keyCode, ctrlKey, altKey, shiftKey, metaKey);
  } else {
    event.initKeyEvent(type, true, true, document.defaultView, ctrlKey, altKey,
        shiftKey, metaKey, keyCode, keyCode);
  }

  return event;
}
''';

Event createKeyboardEvent(
  String type,
  int keyCode, {
  bool ctrlKey: false,
  bool altKey: false,
  bool shiftKey: false,
  bool metaKey: false,
}) {
  if (!context.hasProperty(CREATE_KEYBOARD_EVENT_NAME)) {
    var script = document.createElement('script')
      ..setAttribute('type', 'text/javascript')
      ..text = CREATE_KEYBOARD_EVENT_SCRIPT;
    document.body.append(script);
  }
  return context.callMethod(CREATE_KEYBOARD_EVENT_NAME,
      [type, keyCode, ctrlKey, altKey, shiftKey, metaKey]);
}
