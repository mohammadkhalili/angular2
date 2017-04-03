@TestOn('browser')
library angular2.test.compiler.shadow_css_test;

import 'package:angular2/src/compiler/shadow_css.dart';
import "package:angular2/src/testing/internal.dart";
import 'package:test/test.dart';

const content = 'content';
const host = 'host';

/// Shims [css] and compares to the [expected] output for both current and
/// legacy encapsulation.
void shimAndExpect(String css, String expected, {String expectedLegacy}) {
  var actual = shimShadowCss(css, content, host);
  var actualLegacy =
      shimShadowCss(css, content, host, useLegacyEncapsulation: true);
  expect(normalizeCSS(actual), expected);
  expect(normalizeCSS(actualLegacy), expectedLegacy ?? expected);
}

/// Shims [css] and compares to the [expected] output for legacy syntax only.
void legacyShimAndExpect(String css, String expected) {
  var actual = shimShadowCss(css, content, host, useLegacyEncapsulation: true);
  expect(normalizeCSS(actual), expected);
}

void main() {
  test('should handle empty string', () => shimAndExpect('', ''));

  test('should add a class to every rule', () {
    var css = 'one {color: red;} two {color: red;}';
    var expected = 'one.$content {color:red;} two.$content {color:red;}';
    shimAndExpect(css, expected);
    shimAndExpect(css, expected);
  });

  test('should add a class to every selector', () {
    var css = 'one,two {color: red;}';
    var expected = 'one.$content,two.$content {color:red;}';
    shimAndExpect(css, expected);
  });

  test('should support newlines in the selector and content ', () {
    var css = 'one,\ntwo {\ncolor: red;}';
    var expected = 'one.$content,two.$content {color:red;}';
    shimAndExpect(css, expected);
  });

  test('should handle media rules', () {
    var css = '@media screen and (max-width:800px) {div {font-size:50px;}}';
    var expected =
        '@media screen AND (max-width:800px) {div.$content {font-size:50px;}}';
    shimAndExpect(css, expected);
  });

  test('should handle page rules', () {
    var css = '@page {@top-left {color:red;} font-size:50px;}';
    shimAndExpect(css, css);
  });

  test('should handle media rules with simple rules', () {
    var css = '@media screen and (max-width: 800px) '
        '{div {font-size: 50px;}} div {}';
    var expected = '@media screen AND (max-width:800px) '
        '{div.$content {font-size:50px;}} div.$content {}';
    shimAndExpect(css, expected);
  });

  // Check that the browser supports unprefixed CSS animation
  test('should handle keyframes rules', () {
    var css = '@keyframes foo{0%{transform:translate(-50%) scaleX(0);}}';
    shimAndExpect(css, css);
  });

  test('should handle -webkit-keyframes rules', () {
    var css = '@-webkit-keyframes foo'
        '{0%{-webkit-transform:translate(-50%) scaleX(0);}}';
    shimAndExpect(css, css);
  });

  test('should handle complicated selectors', () {
    shimAndExpect('one::before {}', 'one.$content::before {}');
    shimAndExpect('one two {}', 'one.$content two.$content {}');
    shimAndExpect('one > two {}', 'one.$content > two.$content {}');
    shimAndExpect('one + two {}', 'one.$content + two.$content {}');
    shimAndExpect('one ~ two {}', 'one.$content ~ two.$content {}');
    shimAndExpect('.one.two > four {}', '.one.two.$content > four.$content {}');
    shimAndExpect('one[attr="value"] {}', 'one[attr="value"].$content {}');
    shimAndExpect('one[attr=value] {}', 'one[attr="value"].$content {}');
    shimAndExpect('one[attr^="value"] {}', 'one[attr^="value"].$content {}');
    shimAndExpect('one[attr\$="value"] {}', 'one[attr\$="value"].$content {}');
    shimAndExpect('one[attr*="value"] {}', 'one[attr*="value"].$content {}');
    shimAndExpect('one[attr|="value"] {}', 'one[attr|="value"].$content {}');
    shimAndExpect('one[attr~="value"] {}', 'one[attr~="value"].$content {}');
    shimAndExpect('one[attr="va lue"] {}', 'one[attr="va lue"].$content {}');
    shimAndExpect('one[attr] {}', 'one[attr].$content {}');
    shimAndExpect('[is="one"] {}', '[is="one"].$content {}');
  });

  test('should handle scoping legacy pseudo-elements', () {
    shimAndExpect('.x:after {}', '.x.$content:after {}');
  });

  group(':host', () {
    test('should handle basic use', () {
      shimAndExpect(':host {}', '.$host {}');
    });

    test('should handle pseudo-element', () {
      shimAndExpect(':host::after {}', '.$host::after {}');
    });

    test('should handle compound selector', () {
      shimAndExpect(':host.x::before {}', '.$host.x::before {}');
    });

    test("shouldn't scope siblings", () {
      shimAndExpect(':host + .x {}', '.$host + .x {}');
      shimAndExpect(':host ~ .x {}', '.$host ~ .x {}');
    });

    test('should differentiate legacy encapsulation', () {
      shimAndExpect(':host p {}', '.$host p.$content {}',
          expectedLegacy: '.$host p {}');
    });
  });

  group(':host()', () {
    test('should handle tag selector argument', () {
      shimAndExpect(':host(ul) {}', 'ul.$host {}');
    });

    test('should handle name selector argument', () {
      shimAndExpect(':host(#x) {}', '.$host#x {}');
    });

    test('should handle class selector argument', () {
      shimAndExpect(':host(.x) {}', '.$host.x {}');
    });

    test('should handle attribute selector argument', () {
      shimAndExpect(':host([a="b"]) {}', '.$host[a="b"] {}');
      shimAndExpect(':host([a=b]) {}', '.$host[a="b"] {}');
    });

    test('should handle pseudo-class selector argument', () {
      var css = ':host(:nth-child(2n+1)) {}';
      var expected = '.$host:nth-child(2n+1) {}';
      shimAndExpect(css, expected);
    });

    test('should handle pseudo-element selector argument', () {
      shimAndExpect(':host(::before) {}', '.$host::before {}');
    });

    test('should handle compound selector argument', () {
      shimAndExpect(':host(a.x:active) {}', 'a.$host.x:active {}');
    });

    test('should handle pseudo-element', () {
      shimAndExpect(':host(.x)::before {}', '.$host.x::before {}');
    });

    test('should handle complex selector', () {
      shimAndExpect(
        ':host(.x) > .y {}',
        '.$host.x > .y.$content {}',
        expectedLegacy: '.$host.x > .y {}',
      );
    });

    test('should handle multiple selectors', () {
      shimAndExpect(':host(.x),:host(a) {}', '.$host.x,a.$host {}');
    });

    test("shouldn't shim siblings", () {
      shimAndExpect(':host(.x) + .y {}', '.$host.x + .y {}');
      shimAndExpect(':host(.x) ~ .y {}', '.$host.x ~ .y {}');
    });
  });

  group(':host-context()', () {
    test('should handle tag selector argument', () {
      shimAndExpect(':host-context(div) {}', 'div.$host,div .$host {}');
    });

    test('should handle name selector argument', () {
      shimAndExpect(':host-context(#x) {}', '.$host#x,#x .$host {}');
    });

    test('should handle class selector argument', () {
      shimAndExpect(':host-context(.x) {}', '.$host.x,.x .$host {}');
    });

    test('should handle attribute selector argument', () {
      var css = ':host-context([a="b"]) {}';
      var expected = '.$host[a="b"],[a="b"] .$host {}';
      shimAndExpect(css, expected);
    });

    test('should handle pseudo-class selector argument', () {
      var css = ':host-context(:nth-child(2n+1)) {}';
      var expected = '.$host:nth-child(2n+1),:nth-child(2n+1) .$host {}';
      shimAndExpect(css, expected);
    });

    test('should handle pseudo-element selector argument', () {
      var css = ':host-context(::before) {}';
      var expected = '.$host::before,::before .$host {}';
      shimAndExpect(css, expected);
    });

    test('should handle compound selector argument', () {
      var css = ':host-context(a.x:active) {}';
      var expected = 'a.$host.x:active,a.x:active .$host {}';
      shimAndExpect(css, expected);
    });

    test('should handle complex selector', () {
      var css = ':host-context(.x) > .y {}';
      var expected = '.$host.x > .y.$content,.x .$host > .y.$content {}';
      var expectedLegacy = '.$host.x > .y,.x .$host > .y {}';
      shimAndExpect(css, expected, expectedLegacy: expectedLegacy);
    });

    test('should handle multiple selectors', () {
      var css = ':host-context(.x),:host-context(.y) {}';
      var expected = '.$host.x,.x .$host,.$host.y,.y .$host {}';
      shimAndExpect(css, expected);
    });

    test("shouldn't shim siblings", () {
      var css = ':host-context(.x) + .y {}';
      shimAndExpect(css, '.$host.x + .y,.x .$host + .y {}');
      css = ':host-context(.x) ~ .y {}';
      shimAndExpect(css, '.$host.x ~ .y,.x .$host ~ .y {}');
    });
  });

  // Each host selector contributes a host class. For now this duplication is
  // not a concern as it doesn't affect what the shimmed selector matches.
  group(':host-context():host()', () {
    test('should handle combination', () {
      var css = ':host-context(.x):host(.y) {}';
      var expected = '.$host.$host.x.y,.x .$host.$host.y {}';
      shimAndExpect(css, expected);
    });

    test('should handle combination reversed', () {
      var css = ':host(.y):host-context(.x) {}';
      var expected = '.$host.$host.y.x,.x .$host.$host.y {}';
      shimAndExpect(css, expected);
    });

    test('should handle non-trivial combination', () {
      var css = ':host(div::scrollbar:vertical):host-context(.foo:hover) {}';
      var expected = 'div.$host.$host.foo:hover::scrollbar:vertical,'
          '.foo:hover div.$host.$host::scrollbar:vertical {}';
      shimAndExpect(css, expected);
    });
  });

  group('legacy', () {
    test('should support polyfill-next-selector', () {
      var css = "polyfill-next-selector {content: 'x > y';} z {}";
      legacyShimAndExpect(css, 'x.$content > y.$content {}');
      css = 'polyfill-next-selector {content: "x > y";} z {}';
      legacyShimAndExpect(css, 'x.$content > y.$content {}');
      css = 'polyfill-next-selector {content: \'button[priority="1"]\';} z {}';
      legacyShimAndExpect(css, 'button[priority="1"].$content {}');
    });

    test('should support polyfill-unscoped-rule', () {
      var css = "polyfill-unscoped-rule {content: '#menu > .bar';color: blue;}";
      legacyShimAndExpect(css, '#menu > .bar {color:blue;}');
      css = 'polyfill-unscoped-rule {content: "#menu > .bar";color: blue;}';
      legacyShimAndExpect(css, '#menu > .bar {color:blue;}');
      css = 'polyfill-unscoped-rule {content: \'button[priority="1"]\';}';
      legacyShimAndExpect(css, 'button[priority="1"] {}');
    });

    test('should support multiple instances polyfill-unscoped-rule', () {
      var css = 'polyfill-unscoped-rule {content: "foo";color: blue;}' +
          'polyfill-unscoped-rule {content: "bar";color: red;}';
      legacyShimAndExpect(css, 'foo {color:blue;} bar {color:red;}');
    });

    test('should handle ::content', () {
      legacyShimAndExpect('x::content > y {}', 'x.$content > y.$content {}');
      legacyShimAndExpect('::content y {}', 'y.$content {}');
      legacyShimAndExpect(':host ::content div', '.$host div {}');
    });

    test('should handle ::shadow', () {
      legacyShimAndExpect('x::shadow > y {}', 'x.$content > y.$content {}');
      legacyShimAndExpect('::shadow y {}', 'y.$content {}');
      legacyShimAndExpect(':host ::shadow div', '.$host div {}');
    });
  });

  test('should handle /deep/', () {
    var css = 'x /deep/ y {}';
    shimAndExpect(css, 'x.$content y {}');
    css = '/deep/ x {}';
    shimAndExpect(css, 'x {}');
  });

  test('should handle >>>', () {
    var css = 'x >>> y {}';
    shimAndExpect(css, 'x.$content y {}');
    css = '>>> y {}';
    shimAndExpect(css, 'y {}');
  });

  test('should handle sequential shadow piercing combinators', () {
    // Current SASS practices cause frequent occurrences of duplicate shadow
    // piercing combinators in the generated CSS.
    var css = 'x /deep/ /deep/ y {}';
    shimAndExpect(css, 'x.$content y {}');
    css = 'x >>> >>> y {}';
    shimAndExpect(css, 'x.$content y {}');
    css = 'x /deep/ >>> y {}';
    shimAndExpect(css, 'x.$content y {}');
  });

  test('should pass through @import directives', () {
    var css = '@import url("https://fonts.googleapis.com/css?family=Roboto");';
    shimAndExpect(css, css);
  });

  test('should shim rules after @import', () {
    var css = '@import url("a"); div {}';
    shimAndExpect(css, '@import url("a"); div.$content {}');
  });

  test('should leave calc() unchanged', () {
    var css = 'div {height:calc(100% - 55px);}';
    shimAndExpect(css, 'div.$content {height:calc(100% - 55px);}');
  });

  test('should strip comments', () {
    shimAndExpect('/* x */b {}', 'b.$content {}');
  });

  test('should ignore special characters in comments', () {
    shimAndExpect('/* {;, */b {}', 'b.$content {}');
  });

  test('should support multiline comments', () {
    shimAndExpect('/* \n */b {}', 'b.$content {}');
  });

  test("should handle pseudo element's pseudo class", () {
    var css = '::-webkit-scrollbar-thumb:vertical {}';
    var expected = '.$content::-webkit-scrollbar-thumb:vertical {}';
    shimAndExpect(css, expected);
  });
}
