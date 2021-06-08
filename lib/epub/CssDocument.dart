import 'dart:collection';
import 'dart:math' as math;
import 'package:csslib/parser.dart' as css;
import 'package:csslib/visitor.dart';
import 'package:xml_test/common.dart';
import 'package:xml_test/xml/xnode.dart' as xnode;

// ignore_for_file: unnecessary_cast
// ignore_for_file: unnecessary_this
// ignore_for_file: omit_local_variable_types

typedef CssFunctionHandler = CssValue? Function(CssFunction function);
typedef CssDeclarationHandler = bool Function(CssRuleSet ruleset, CssDeclaration declaration);

class CssDocument extends Visitor
{
    static const INLINE_STYLE_SELECTOR = '__x_element__';

    static final empty = CssDocument('');

    static final functions = <String, CssFunctionHandler>
    {
    'rgb': _rgbFunction,
    'rgba': _rgbaFunction,
    'hsl': _hslaFunction,
    'hsla': _hslaFunction,
    };

    static final declarationMappers = <String, CssDeclarationHandler>
    {
    'margin': _delarationMargin,
    'padding': _delarationMargin,
    };

    final treeStack = Queue<CssTreeItem>();
    final rules = <CssRuleSet>[];

    CssDocument(String cssText)
    {
        var stylesheet = css.parse(cssText);

        stylesheet.visit(this);
        _expandDeclarations();
    }

    void _expandDeclarations()
    {
        for (final ruleset in rules)
        {
            ruleset.declarationIndex = null;

            for (final declaration in ruleset.declarations.toList())
            {
                bool remove = declarationMappers[declaration.name]?.call(ruleset, declaration) ?? false;
                if (remove)
                {
                    ruleset.declarations.removeWhere((item) => item.name == declaration.name);
                }
            }
        }
    }

    CssDeclarationResult findDeclaration(xnode.TreeNode node, String propetyName, [CssDeclarationResult? resultHolder])
    {
        final result = (resultHolder ?? CssDeclarationResult());

        for (final ruleset in rules)
        {
            final property = ruleset.declarationByName(propetyName);

            if (property != null)
            {
                for (final selector in ruleset.selectors)
                {
                    if (selector.specificity >= result.specificity)
                    {
                        if (selector.checkNode(node))
                        {
                            result.declaration = property;
                            result.specificity = selector.specificity;
                        }
                    }
                }
            }
        }

        return result;
    }

    Map<String, CssDeclarationResult> getNodeStyle(xnode.TreeNode node,
            [Map<String, CssDeclarationResult>? resultHolder])
    {
        final result = resultHolder ?? <String, CssDeclarationResult>{};

        for (final ruleset in rules)
        {
            for (final selector in ruleset.selectors)
            {
                if (selector.checkNode(node))
                {
                    for (final declaration in ruleset.declarations)
                    {
                        final declInfo = result[declaration.name];

                        if (declInfo == null)
                        {
                            result[declaration.name] = CssDeclarationResult.fromDeclaration(declaration, selector.specificity);
                        }
                        else if (selector.specificity >= declInfo.specificity)
                        {
                            declInfo.declaration = declaration;
                            declInfo.specificity = selector.specificity;
                        }
                    }
                }
            }
        }

        return result;
    }

    @override
    String toString()
    {
        final builder = StringBuffer();

        for (var rule in rules)
        {
            builder.write(rule.toString());
        }

        return builder.toString();
    }

    @override
    void visitRuleSet(RuleSet node)
    {
//#verbose
        print('Ruleset');
//#end VERBOSE line:138

        if (treeStack.isNotEmpty)
        {
            throw Exception('Tree stack must be empty');
        }

        final ruleSet = CssRuleSet(this);
        treeStack.add(ruleSet);
        rules.add(ruleSet);
        super.visitRuleSet(node);
        treeStack.removeLast();
    }

    @override
    void visitSelectorGroup(SelectorGroup node)
    {
//#verbose
        print('SelectorGroup ${node.span!.text}');
//#end VERBOSE line:157

        super.visitSelectorGroup(node);
    }

    @override
    void visitSelector(Selector node)
    {
//#verbose
        print('  Selector:${node.span!.text}');
//#end VERBOSE line:167

        var selector = CssSelector(this);
        treeStack.last.insert(selector);
        treeStack.add(selector);

        super.visitSelector(node);

        treeStack.removeLast();
    }

    @override
    void visitSimpleSelectorSequence(SimpleSelectorSequence node)
    {
//#verbose
        var s = node.span!.text;
        print('SimpleSelectorSequence $s');
//#end VERBOSE line:183
        treeStack.last.insert(node);
        super.visitSimpleSelectorSequence(node);
    }

    @override
    void visitAttributeSelector(AttributeSelector node)
    {
//#verbose
        print('AttributeSelector');
//#end VERBOSE line:194
        super.visitAttributeSelector(node);

        treeStack.last.insert(node);
//#verbose
        final tokenStr = node.matchOperatorAsTokenString();
        final value = node.valueToString();
        print('operator: ${node.matchOperator()} ($tokenStr)');
        print('value $value');
//#end VERBOSE line:200
    }

    @override
    void visitClassSelector(ClassSelector node)
    {
//#verbose
        print('Class Selector');
//#end VERBOSE line:211

        (treeStack.last as CssSelector).first!.type = CssSimpleSelector.SELECTOR_CLASS;
        super.visitClassSelector(node);
    }

    @override
    void visitPseudoClassSelector(PseudoClassSelector node)
    {
//#verbose
        print('Pseudo Class Selector');
//#end VERBOSE line:222
        (treeStack.last as CssSelector).first!.type = CssSimpleSelector.SELECTOR_PSEUDO_CLASS;
        super.visitPseudoClassSelector(node);
    }

    @override
    void visitPseudoElementSelector(PseudoElementSelector node)
    {
//#verbose
        print('Pseudo Element Selector');
//#end VERBOSE line:232
        (treeStack.last as CssSelector).first!.type = CssSimpleSelector.SELECTOR_PSEUDO_ELEMENT;
        super.visitPseudoElementSelector(node);
    }

    @override
    void visitIdSelector(IdSelector node)
    {
//#verbose
        print('Id Selector');
//#end VERBOSE line:242

        (treeStack.last as CssSelector).first!.type = CssSimpleSelector.SELECTOR_ID;
        super.visitIdSelector(node);
    }

    @override
    void visitElementSelector(ElementSelector node)
    {
//#verbose
        print('Element Selector');
//#end VERBOSE line:253

        (treeStack.last as CssSelector).first!.type = CssSimpleSelector.SELECTOR_ELEMENT;
        super.visitElementSelector(node);
    }

    @override
    void visitDeclaration(Declaration node)
    {
//#verbose
        print('Declaration');
//#end VERBOSE line:264

        var declaration = CssDeclaration(this);
        treeStack.last.insert(declaration);
        treeStack.add(declaration);
        super.visitDeclaration(node);
        treeStack.removeLast();
    }

    @override
    void visitIdentifier(Identifier node)
    {
//#verbose
        print('Identifier: ${node.name}');
//#end VERBOSE line:278
        treeStack.last.insert(node);
        super.visitIdentifier(node);
    }

    @override
    void visitLengthTerm(LengthTerm node)
    {
//#verbose
        print('  Length:${node.value} ${node.unitToString()}');
//#end VERBOSE line:288

        treeStack.last.insert(CssNumber.fromUnitTherm(node));
        //super.visitLengthTerm(node);
    }

    @override
    void visitEmTerm(EmTerm node)
    {
//#verbose
        print('  Length:${node.value} em');
//#end VERBOSE line:299

        treeStack.last.insert(CssNumber.fromEmTherm(node));
        //super.visitEmTerm(node);
    }

    @override
    void visitNumberTerm(NumberTerm node)
    {
//#verbose
        print('  Length:${node.value}');
//#end VERBOSE line:310

        treeStack.last.insert(CssValue.fromNode(node));
        super.visitNumberTerm(node);
    }

    @override
    void visitLiteralTerm(LiteralTerm node)
    {
//#verbose
        print('  Literal:${node.text}');
//#end VERBOSE line:321

        treeStack.last.insert(CssValue.fromNode(node));
        super.visitLiteralTerm(node);
    }

    @override
    void visitHexColorTerm(HexColorTerm node)
    {
//#verbose
        print('  HexColor:${node.text}');
//#end VERBOSE line:332

        treeStack.last.insert(CssColor.fromHex(node.text));
        super.visitHexColorTerm(node);
    }

    @override
    void visitUnitTerm(UnitTerm node)
    {
//#verbose
        print('  Unit:${node.text} ${node.unitToString()}');
//#end VERBOSE line:343

        treeStack.last.insert(CssNumber.fromUnitTherm(node));
        super.visitUnitTerm(node);
    }

    @override
    void visitOperatorComma(OperatorComma node)
    {
//#verbose
        print('  Operator comma');
//#end VERBOSE line:354

        treeStack.last.insert(CssValue.fromNode(node));
        super.visitOperatorComma(node);
    }

    @override
    void visitFunctionTerm(FunctionTerm node)
    {
//#verbose
        print('  Function:${node.text}');
//#end VERBOSE line:365

        var cssFunction = CssFunction(this);

        treeStack.add(cssFunction);
        super.visitFunctionTerm(node);
        treeStack.removeLast();

        var name = cssFunction.name;

        if (functions.containsKey(name))
        {
            var f = functions[name];

            var result = (f != null) ? f(cssFunction) : null;

            if (result != null)
            {
                treeStack.last.insert(result);
            }
        }
    }

    @override
    void visitUriTerm(UriTerm node)
    {
//#verbose
        print('  Uri:${node.text}');
//#end VERBOSE line:393
        treeStack.last.insert(CssUri(node.text));
    }

    @override
    dynamic visitFontFaceDirective(FontFaceDirective node)
    {
//#verbose
        print('Font face');
//#end VERBOSE line:402
        final fontFace = CssFontFace(this);
        treeStack.add(fontFace);
        rules.add(fontFace);

        super.visitFontFaceDirective(node);

        treeStack.removeLast();
    }

    @override
    void visitPageDirective(PageDirective node)
    {
//#verbose
        print('Page');
//#end VERBOSE line:417

        final page = CssPage(this);
        treeStack.add(page);
        rules.add(page);

        super.visitPageDirective(node);

        treeStack.removeLast();
    }

    @override
    void visitMediaDirective(MediaDirective node)
    {
//#verbose
        print('Media  (ignored)');
//#end VERBOSE line:433
    }

    @override
    void visitKeyFrameDirective(KeyFrameDirective node)
    {
//#verbose
        print('Keyframes  (ignored)');
//#end VERBOSE line:441
    }
}

class CssTreeItem
{
    late final Queue<CssTreeItem> _treeStack;
    late final CssDocument decoder;

    CssTreeItem(this.decoder)
    {
        _treeStack = decoder.treeStack;
    }

    void insert(Object child) {}

    void push(CssTreeItem item)
    {
        _treeStack.add(item);
    }

    void pop()
    {
        _treeStack.removeLast();
    }

    CssTreeItem get treeItem => _treeStack.last;
}

class CssRuleSet extends CssTreeItem
{
    var selectors = <CssSelector>[];
    var declarations = <CssDeclaration>[];
    Map<String, CssDeclaration>? declarationIndex;

    CssRuleSet(CssDocument decoder) : super(decoder);

    CssRuleSet.fromDeclarationResult(List<MapEntry<String, CssDeclarationResult>> declResult, {String? className})
            : super(CssDocument.empty)
    {
        if (className != null)
        {
            selectors.add(CssSelector.fromClassName(decoder, className));
        }

        for (final decl in declResult)
        {
            if (decl.value.declaration != null)
            {
                declarations.add(decl.value.declaration!);
            }
        }
    }

    void setSelectorClass(String className)
    {
        selectors.clear();
        selectors.add(CssSelector.fromClassName(decoder, className));
    }

    @override
    void insert(Object child)
    {
        if (child is CssSelector)
        {
            selectors.add(child as CssSelector);
        }
        else if (child is CssDeclaration)
        {
            declarations.add(child as CssDeclaration);
            declarationIndex = null;
        }
    }

    CssDeclaration? declarationByName(String name)
    {
        CssDeclaration? result;

        if (declarationIndex == null)
        {
            final index = <String, CssDeclaration>{};

            for (final declaration in declarations)
            {
                if (declaration.name != '')
                {
                    index[declaration.name] = declaration;
                }
            }

            declarationIndex = index;
        }

        result = declarationIndex![name];

        return result;
    }

    @override
    String toString()
    {
        final builder = StringBuffer();
        var firstSelector = true;

        if (selectors.isNotEmpty)
        {
            for (var selector in selectors)
            {
                if (!firstSelector)
                {
                    builder.write(',');
                }

                firstSelector = false;
                builder.write(selector.toString());
            }

            builder.write('{\r\n');
            for (var declaration in declarations)
            {
                builder.write('   ');
                builder.write(declaration.toString());
                builder.write(';\r\n');
            }
            builder.write('}\r\n');
        }
        else
        {
            for (var declaration in declarations)
            {
                builder.write(declaration.toString());
                builder.write('; ');
            }
        }

        return builder.toString();
    }
}

class CssFontFace extends CssRuleSet
{
    CssFontFace(CssDocument decoder) : super(decoder)
    {
        final selector = CssSelector(decoder);
        selector.selectors.add(CssSimpleSelector.asFontFace());
        this.selectors.add(selector);
    }
}

class CssPage extends CssRuleSet
{
    CssPage(CssDocument decoder) : super(decoder)
    {
        final selector = CssSelector(decoder);
        selector.selectors.add(CssSimpleSelector.asPage());
        this.selectors.add(selector);
    }
}

class CssSelector extends CssTreeItem
{
    CssSimpleSelector? first;
    var selectors = <CssSimpleSelector>[];

    CssSelector(CssDocument decoder) : super(decoder);

    int get specificity
    {
        int result = 0;

        for (final selector in selectors)
        {
            result += selector.specificity;
        }

        return result;
    }

    CssSelector.fromClassName(CssDocument decoder, String className) : super(decoder)
    {
        selectors.add(CssSimpleSelector.fromClassName(className));
    }

    bool checkNode(xnode.TreeNode node)
    {
        bool result = false;
        var selector = first;

        if (selector != null)
        {
            result = selector.check(node);
        }

        return result;
    }

    @override
    void insert(Object child)
    {
        if (child is SimpleSelectorSequence)
        {
            var selector = CssSimpleSelector();
            var node = child as SimpleSelectorSequence;

            if (node.isCombinatorDescendant)
            {
                selector.type = CssSimpleSelector.COMBINATOR_DESCENDANT;
            }
            else if (node.isCombinatorGreater)
            {
                selector.type = CssSimpleSelector.COMBINATOR_GREATER;
            }
            else if (node.isCombinatorPlus)
            {
                selector.type = CssSimpleSelector.COMBINATOR_PLUS;
            }
            else if (node.isCombinatorTilde)
            {
                selector.type = CssSimpleSelector.COMBINATOR_TILDE;
            }
            else
            {
                selector.type = CssSimpleSelector.COMBINATOR_NONE;
            }

            selector.next = first;
            first = selector;
            selectors.add(selector);
        }
        else if (child is Identifier)
        {
            final name = (child as Identifier).name;
            first!.text = name;
            if (name == CssDocument.INLINE_STYLE_SELECTOR)
            {
                first!.type = CssSimpleSelector.SELECTOR_INLINE;
            }
        }
        else if (child is AttributeSelector)
        {
            selectors.last.setOperation(child as AttributeSelector);
        }
    }

    @override
    String toString()
    {
        final builder = StringBuffer();

        for (var selector in selectors)
        {
            builder.write(selector.toString());
        }

        return builder.toString();
    }
}

class CssDeclaration extends CssTreeItem
{
    late CssRuleSet _ruleSet;
    String name = '';
    var values = <CssValue>[];

    CssDeclaration(CssDocument decoder) : super(decoder)
    {
        _ruleSet = decoder.treeStack.last as CssRuleSet;
    }

    CssDeclaration.fromValues(CssRuleSet ruleset, this.name, this.values) : super(ruleset.decoder)
    {
        _ruleSet = ruleset;
    }

    @override
    void insert(Object child)
    {
        if (child is Identifier)
        {
            name = (child as Identifier).name;
        }
        else if (child is CssValue)
        {
            values.add(child as CssValue);
        }
    }

    @override
    String toString()
    {
        var builder = StringBuffer();
        builder.write(name);
        builder.write(': ');
        var first = true;

        for (var value in values)
        {
            if (!first)
            {
                builder.write(' ');
            }
            first = false;
            builder.write(value.toString());
        }

        return builder.toString();
    }
}

class CssFunction extends CssTreeItem
{
    String name = '';
    var params = <CssValue>[];

    CssFunction(CssDocument decoder) : super(decoder);

    @override
    void insert(Object child)
    {
        if (name == '')
        {
            name = (child is CssLiteral) ? (child as CssLiteral).text.toLowerCase() : '???';
        }
        else
        {
            params.add(child as CssValue);
        }
    }
}

abstract class CssValue
{
    static CssValue fromNode(Object node)
    {
        if (node is NumberTerm)
        {
            return CssNumber.fromNumberTherm(node as NumberTerm);
        }
        else if (node is LiteralTerm)
        {
            var literal = node as LiteralTerm;

            switch (literal.text)
            {
                case 'inherited':
                    return CssInherited();
                default:
                    return CssLiteral(literal.text);
            }
        }
        else if (node is OperatorComma)
        {
            return CssOperatorComma();
        }

        return CssInherited();
    }
}

class CssNumber extends CssValue
{
    double value = 0.0;
    String unit = '';

    CssNumber.fromNumberTherm(NumberTerm number)
    {
        try
        {
            var val = double.tryParse(number.text);
            if (val != null)
            {
                this.value = val;
            }
        }
        catch (ex)
        {
            value = 0.0;
        }
    }

    CssNumber.fromUnitTherm(UnitTerm unit)
    {
        this.value = dynamicToDouble(unit.value);
        this.unit = unit.unitToString() ?? '';
    }

    CssNumber.fromCssNumber(CssNumber src)
    {
        value = src.value;
        unit = src.unit;
    }

    CssNumber.fromEmTherm(EmTerm number)
    {
        try
        {
            var val = double.tryParse(number.text);
            if (val != null)
            {
                this.value = val;
            }
        }
        catch (ex)
        {
            value = 0.0;
        }

        unit = 'em';
    }

    double valueSat(double min, double max)
    {
        return value < min
                ? min
                : value > max
                        ? max
                        : value;
    }

    int valueInt(int min, int max)
    {
        return valueSat(min.toDouble(), max.toDouble()).toInt();
    }

    String valueString()
    {
        return (value == value.ceil()) ? value.toStringAsFixed(0) : value.toString();
    }

    @override
    String toString()
    {
        return '${valueString()}$unit';
    }
}

class CssInherited extends CssValue {}

class CssLiteral extends CssValue
{
    String text;

    CssLiteral(this.text);

    @override
    String toString()
    {
        return text;
    }
}

class CssUri extends CssLiteral
{
    CssUri(String text) : super(text);

    @override
    String toString()
    {
        return 'url($text)';
    }
}

class CssColor extends CssValue
{
    int red = 0;
    int green = 0;
    int blue = 0;
    int alpha = 255;

    CssColor.fromRgba(int red, int green, int blue, int alpha)
    {
        this.red = saturateInt(red, 0, 255);
        this.green = saturateInt(green, 0, 255);
        this.blue = saturateInt(blue, 0, 255);
        this.alpha = saturateInt(alpha, 0, 255);
    }

    CssColor.fromRgbaInt(int color)
    {
        this.red = 0xff & (color >> 24);
        this.green = 0xff & (color >> 16);
        this.blue = 0xff & (color >> 8);
        this.alpha = 0xff & color;
    }

    CssColor.fromHex(String hexColor)
    {
        var t = hexColor;

        switch (t.length)
        {
            case 3:
                t = t.substring(0, 1) +
                        t.substring(0, 1) +
                        t.substring(1, 2) +
                        t.substring(1, 2) +
                        t.substring(2, 3) +
                        t.substring(2, 3) +
            'ff';
                break;
            case 4:
                t = t.substring(0, 1) +
                        t.substring(0, 1) +
                        t.substring(1, 2) +
                        t.substring(1, 2) +
                        t.substring(2, 3) +
                        t.substring(2, 3) +
                        t.substring(3, 4) +
                        t.substring(3, 4);
                break;
            case 6:
                t = t + 'ff';
                break;
            case 8:
                break;
            default:
                t = '000000ff';
        }

        red = int.parse(t.substring(0, 2), radix: 16);
        green = int.parse(t.substring(2, 4), radix: 16);
        blue = int.parse(t.substring(4, 6), radix: 16);
        alpha = int.parse(t.substring(6, 8), radix: 16);
    }

    @override
    String toString()
    {
        var result = '#' +
                red.toRadixString(16).padLeft(2, '0') +
                green.toRadixString(16).padLeft(2, '0') +
                blue.toRadixString(16).padLeft(2, '0');

        if (alpha != 0xff)
        {
            result += alpha.toRadixString(16).padLeft(2, '0');
        }

        return result;
    }

    int get rgbaInt
    {
        return ((red & 0xff) << 24) | ((green & 0xff) << 16) | ((blue & 0xff) << 8) | (alpha & 0xff);
    }
}

class CssSimpleSelector
{
    static const COMBINATOR_NONE = 0;
    static const COMBINATOR_DESCENDANT = 1;
    static const COMBINATOR_PLUS = 2;
    static const COMBINATOR_GREATER = 3;
    static const COMBINATOR_TILDE = 4;

    static const SELECTOR_ELEMENT = 0;
    static const SELECTOR_ID = 1;
    static const SELECTOR_CLASS = 2;
    static const SELECTOR_ATTRIBUTE = 3;
    static const SELECTOR_PSEUDO_CLASS = 4;
    static const SELECTOR_PSEUDO_ELEMENT = 5;
    static const SELECTOR_FONT_FACE = 6;
    static const SELECTOR_PAGE = 7;
    static const SELECTOR_INLINE = 8;

    static const OPERATION_NONE = 0;
    static const OPERATION_EQUAL = 1;
    static const OPERATION_INCLUDES = 2;
    static const OPERATION_DASH_MATCH = 2;
    static const OPERATION_PREFIX_MATCH = 3;
    static const OPERATION_SUFFIX_MATCH = 4;
    static const OPERATION_SUBSTRING_MATCH = 5;

    CssSimpleSelector? next;
    String text = '';
    int type = SELECTOR_ELEMENT;
    int combinator = COMBINATOR_NONE;
    int operation = OPERATION_NONE;
    String operationString = '';
    String value = '';

    CssSimpleSelector();

    CssSimpleSelector.asFontFace()
    {
        text = '@font-face';
        type = SELECTOR_FONT_FACE;
    }

    CssSimpleSelector.asPage()
    {
        text = '@page';
        type = SELECTOR_PAGE;
    }

    CssSimpleSelector.fromClassName(String className)
    {
        text = className;
        type = SELECTOR_CLASS;
    }

    int get specificity
    {
        switch (type)
        {
            case SELECTOR_INLINE:
                return 1000;

            case SELECTOR_ID:
                return 100;

            case SELECTOR_CLASS:
            case SELECTOR_PSEUDO_CLASS:
            case SELECTOR_ATTRIBUTE:
                return 10;

            default:
                return 1;
        }
    }

    void setOperation(AttributeSelector selector)
    {
        operationString = selector.matchOperator() ?? '';

        value = selector.valueToString();

        type = SELECTOR_ATTRIBUTE;

        switch (operationString)
        {
            case '=':
                operation = OPERATION_EQUAL;
                break;
            case '~=':
                operation = OPERATION_INCLUDES;
                break;
            case '|=':
                operation = OPERATION_DASH_MATCH;
                break;
            case '^=':
                operation = OPERATION_PREFIX_MATCH;
                break;
            case '\$=':
                operation = OPERATION_SUFFIX_MATCH;
                break;
            case '*=':
                operation = OPERATION_SUBSTRING_MATCH;
                break;
            default:
                operation = OPERATION_NONE;
                operationString = '';
        }
    }

    bool check(xnode.TreeNode node)
    {
        bool result = false;

        switch (type)
        {
            case SELECTOR_ELEMENT:
                result = node.xnode.name == text;
                break;
            case SELECTOR_CLASS:
                result = node.classes.contains(text);
                break;
            case SELECTOR_ID:
                result = node.id == text;
                break;
            case SELECTOR_INLINE:
                result = true;
                break;
        }

        return result;
    }

    @override
    String toString()
    {
        var comb = '';
        var tp = '';

        switch (combinator)
        {
            case COMBINATOR_DESCENDANT:
                comb = ' ';
                break;
            case COMBINATOR_PLUS:
                comb = '+';
                break;
            case COMBINATOR_GREATER:
                comb = '>';
                break;
            case COMBINATOR_TILDE:
                comb = '~';
                break;
        }

        switch (type)
        {
            case SELECTOR_ID:
                tp = '#';
                break;
            case SELECTOR_CLASS:
                tp = '.';
                break;
            case SELECTOR_PSEUDO_CLASS:
                tp = ':';
                break;
            case SELECTOR_PSEUDO_ELEMENT:
                tp = '::';
                break;
        }

        switch (type)
        {
            case SELECTOR_ATTRIBUTE:
                return (operation == OPERATION_NONE) ? '[$text]' : '[$text$operationString$value]';

            default:
                return '$comb$tp$text';
        }
    }
}

class CssOperatorComma extends CssValue
{
    @override
    String toString()
    {
        return ',';
    }
}

class CssDeclarationResult
{
    CssDeclaration? declaration;
    int specificity = -1;

    CssDeclarationResult();

    CssDeclarationResult.fromDeclaration(this.declaration, this.specificity);
}

CssValue? _rgbFunction(CssFunction function)
{
    try
    {
        return CssColor.fromRgba((function.params[0] as CssNumber).valueInt(0, 255),
                (function.params[1] as CssNumber).valueInt(0, 255), (function.params[2] as CssNumber).valueInt(0, 255), 255);
    }
    catch (e)
    {
        return CssColor.fromRgba(0, 0, 0, 255);
    }
}

CssValue? _rgbaFunction(CssFunction function)
{
    try
    {
        return CssColor.fromRgba(
                (function.params[0] as CssNumber).valueInt(0, 255),
                (function.params[1] as CssNumber).valueInt(0, 255),
                (function.params[2] as CssNumber).valueInt(0, 255),
                ((function.params[3] as CssNumber).valueSat(0, 1) * 255).toInt());
    }
    catch (e)
    {
        return CssColor.fromRgba(0, 0, 0, 255);
    }
}

CssValue? _hslaFunction(CssFunction function)
{
    try
    {
        double a = 1.0;

        if (function.params.length >= 4)
        {
            a = (function.params[3] as CssNumber).valueSat(0, 1);
        }

        return _hslaToRgba((function.params[0] as CssNumber).value, (function.params[1] as CssNumber).value,
                (function.params[2] as CssNumber).value, a);
    }
    catch (e)
    {
        return CssColor.fromRgba(0, 0, 0, 255);
    }
}

CssValue? _hslaToRgba(double h, double s, double l, double a)
{
    var r = 0;
    var g = 0;
    var b = 0;

    h = saturate(h, 0, 360);
    s = saturate(s, 0, 1);
    l = saturate(s, 0, 1);

    if (s == 0)
    {
        r = g = b = (l * 255).toInt();
    }
    else
    {
        double v1, v2;
        double hue = h / 360;

        v2 = (l < 0.5) ? (l * (1 + s)) : ((l + s) - (l * s));
        v1 = 2 * l - v2;

        r = (255 * _hueToRGB(v1, v2, hue + (1.0 / 3))).toInt();
        g = (255 * _hueToRGB(v1, v2, hue)).toInt();
        b = (255 * _hueToRGB(v1, v2, hue - (1.0 / 3))).toInt();
    }

    return CssColor.fromRgba(r, g, b, (a * 255).toInt());
}

double _hueToRGB(double v1, double v2, double vH)
{
    if (vH < 0)
    {
        vH += 1;
    }

    if (vH > 1)
    {
        vH -= 1;
    }

    if ((6 * vH) < 1)
    {
        return (v1 + (v2 - v1) * 6 * vH);
    }
    else if ((2 * vH) < 1)
    {
        return v2;
    }
    else if ((3 * vH) < 2)
    {
        return (v1 + (v2 - v1) * ((2.0 / 3) - vH) * 6);
    }
    else
    {
        return v1;
    }
}

bool _delarationMargin(CssRuleSet ruleset, CssDeclaration decl)
{
    bool remove = false;

    final name = decl.name;
    final count = math.min(decl.values.length, 4);
    int left = 0, top = 0, right = 0, bottom = 0;

    switch (count)
    {
        case 2:
            left = 1;
            right = 1;
            break;
        case 3:
            left = 1;
            right = 1;
            bottom = 2;
            break;
        case 4:
            left = 3;
            right = 1;
            bottom = 2;
            break;
    }

    if (count > 0)
    {
        ruleset.declarations.add(CssDeclaration.fromValues(ruleset, name + '-left', [decl.values[left]]));
        ruleset.declarations.add(CssDeclaration.fromValues(ruleset, name + '-right', [decl.values[right]]));
        ruleset.declarations.add(CssDeclaration.fromValues(ruleset, name + '-top', [decl.values[top]]));
        ruleset.declarations.add(CssDeclaration.fromValues(ruleset, name + '-bottom', [decl.values[bottom]]));
        remove = true;
    }

    return remove;
}