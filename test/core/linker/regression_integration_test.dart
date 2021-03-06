@TestOn('browser && !js')
import "dart:async";

import 'package:angular2/angular2.dart';
import "package:angular2/src/testing/internal.dart";
import 'package:test/test.dart';

void main() {
  // Place to put reproductions for regressions
  group("regressions", () {
    group("platform pipes", () {
      beforeEachProviders(() => [
            provide(PLATFORM_PIPES, useValue: [PlatformPipe], multi: true)
          ]);
      test("should overwrite them by custom pipes", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          tcb
              .overrideView(
                  MyComp,
                  new View(
                      template: "{{true | somePipe}}", pipes: [CustomPipe]))
              .createAsync(MyComp)
              .then((fixture) {
            fixture.detectChanges();
            expect(fixture.nativeElement, hasTextContent("someCustomPipe"));
            completer.done();
          });
        });
      });
    });
    group("expressions", () {
      test(
          "should evaluate conditional and boolean operators with right precedence - #8244",
          () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          tcb
              .overrideView(
                  MyComp,
                  new View(
                      template:
                          '''{{\'red\' + (true ? \' border\' : \'\')}}'''))
              .createAsync(MyComp)
              .then((fixture) {
            fixture.detectChanges();
            expect(fixture.nativeElement, hasTextContent("red border"));
            completer.done();
          });
        });
      });
    });
    group("providers", () {
      Future<Injector> createInjector(
          TestComponentBuilder tcb, List<dynamic> providers) {
        return tcb
            .overrideProviders(MyComp, [providers])
            .createAsync(MyComp)
            .then((fixture) => fixture.componentInstance.injector);
      }

      test(
          "should support providers with an OpaqueToken that contains a `.` in the name",
          () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var token = new OpaqueToken("a.b");
          var tokenValue = 1;
          createInjector(tcb, [provide(token, useValue: tokenValue)])
              .then((Injector injector) {
            expect(injector.get(token), tokenValue);
            completer.done();
          });
        });
      });
      test("should support providers with string token with a `.` in it",
          () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var token = "a.b";
          var tokenValue = 1;
          createInjector(tcb, [provide(token, useValue: tokenValue)])
              .then((Injector injector) {
            expect(injector.get(token), tokenValue);
            completer.done();
          });
        });
      });
      test("should support providers with an anonymous function", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var token = () => true;
          var tokenValue = 1;
          createInjector(tcb, [provide(token, useValue: tokenValue)])
              .then((Injector injector) {
            expect(injector.get(token), tokenValue);
            completer.done();
          });
        });
      });
      test(
          "should support providers with an OpaqueToken that has a StringMap as value",
          () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var token1 = const OpaqueToken("someToken1");
          var token2 = const OpaqueToken("someToken2");
          var tokenValue1 = {"a": 1};
          var tokenValue2 = {"a": 1};
          createInjector(tcb, [
            provide(token1, useValue: tokenValue1),
            provide(token2, useValue: tokenValue2)
          ]).then((Injector injector) {
            expect(injector.get(token1), tokenValue1);
            expect(injector.get(token2), tokenValue2);
            completer.done();
          });
        });
      });
    });
    test(
        "should allow logging a previous elements class binding via interpolation",
        () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb
            .overrideTemplate(MyComp,
                '''<div [class.a]="true" #el>Class: {{el.className}}</div>''')
            .createAsync(MyComp)
            .then((fixture) {
          fixture.detectChanges();
          expect(fixture.nativeElement, hasTextContent("Class: a"));
          completer.done();
        });
      });
    });
    test(
        "should support ngClass before a component and content projection inside of an ngIf",
        () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb
            .overrideView(
                MyComp,
                new View(
                    template:
                        '''A<cmp-content *ngIf="true" [ngClass]="\'red\'">B</cmp-content>C''',
                    directives: [NgClass, NgIf, CmpWithNgContent]))
            .createAsync(MyComp)
            .then((fixture) {
          fixture.detectChanges();
          expect(fixture.nativeElement, hasTextContent("ABC"));
          completer.done();
        });
      });
    });
  });
}

@Component(selector: "my-comp", template: "")
class MyComp {
  final Injector injector;
  MyComp(this.injector);
}

@Pipe("somePipe", pure: true)
class PlatformPipe implements PipeTransform {
  dynamic transform(dynamic value) {
    return "somePlatformPipe";
  }
}

@Pipe("somePipe", pure: true)
class CustomPipe implements PipeTransform {
  dynamic transform(dynamic value) {
    return "someCustomPipe";
  }
}

@Component(selector: "cmp-content", template: '''<ng-content></ng-content>''')
class CmpWithNgContent {}
