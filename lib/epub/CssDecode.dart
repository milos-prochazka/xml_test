
import 'dart:collection';

import 'package:csslib/parser.dart' as css;
import 'package:csslib/visitor.dart';
import 'package:xml_test/common.dart';

// ignore_for_file: unnecessary_cast
// ignore_for_file: unnecessary_this

typedef CssFunctionHandler = CssValue? Function (CssFunction function);

class CssDecode extends Visitor
{
    static final functions = <String,CssFunctionHandler>
    { 'rgb':_rgbFunction};
    final _treeStack = Queue<CssTreeItem>();
    final rules = <CssRuleSet>[];

    CssDecode(String cssText)
    {
        var stylesheet = css.parse(cssText);

        stylesheet.visit(this);
    }

    @override
    String toString()
    {
        final builder = StringBuffer();

        for(var rule in rules)
        {
            builder.write(rule.toString());
        }

        return builder.toString();
    }

    @override
    void visitRuleSet(RuleSet node)
    {
  //#debug
        print ('Ruleset');
  //#end

        if (_treeStack.isNotEmpty)
        {
            throw Exception('Tree stack must be empty');
        }

        final ruleSet = CssRuleSet(this,_treeStack);
        _treeStack.add(ruleSet);
        rules.add(ruleSet);
        super.visitRuleSet(node);
        _treeStack.removeLast();

    }


    @override
    void visitSelectorGroup(SelectorGroup node)
    {
  //#debug
        print ('SelectorGroup ${node.span!.text}');
  //#end

        super.visitSelectorGroup(node);
    }


    @override
    void visitSelector(Selector node)
    {
  //#debug
      print('  Selector:${node.span!.text}');
  //#end

        var selector = CssSelector(this, _treeStack);
        _treeStack.last.insert(selector);
        _treeStack.add(selector);

        super.visitSelector(node);

        _treeStack.removeLast();

  }


    @override
    void visitSimpleSelectorSequence(SimpleSelectorSequence node)
    {
  //#debug
        var s = node.span!.text;
        print ('SimpleSelectorSequence $s');
  //#end
        _treeStack.last.insert(node);
        super.visitSimpleSelectorSequence(node);
  }

    @override
    void visitClassSelector(ClassSelector node)
    {
//#debug
      print('Class Selector');
//#end

        (_treeStack.last as CssSelector).first!.type = CssSimpleSelector.SELECTOR_CLASS;
        super.visitClassSelector(node);
    }

    @override

    void visitIdSelector(IdSelector node)
    {
//#debug
        print('Id Selector');
//#end

        (_treeStack.last as CssSelector).first!.type = CssSimpleSelector.SELECTOR_ID;
        super.visitIdSelector(node);
    }


  @override
  void visitElementSelector(ElementSelector node)
  {
//#debug
        print('Element Selector');
//#end

        (_treeStack.last as CssSelector).first!.type = CssSimpleSelector.SELECTOR_ELEMENT;
        super.visitElementSelector(node);
  }

  @override
  void visitDeclaration(Declaration node)
  {
//#debug
        print('Declaration');
//#end

        var declaration = CssDeclaration(this, _treeStack);
        _treeStack.last.insert(declaration);
        _treeStack.add(declaration);
        super.visitDeclaration(node);
        _treeStack.removeLast();
  }


    @override
    void visitIdentifier(Identifier node)
    {
//#debug
      print ('Identifier: ${node.name}');
//#end
      _treeStack.last.insert(node);
      super.visitIdentifier(node);
    }

    @override
    void visitLengthTerm(LengthTerm node)
    {
//#debug
      print('  Length:${node.value} ${node.unitToString()}');
//#end

      _treeStack.last.insert(CssNumber.fromUnitTherm(node));
      //super.visitLengthTerm(node);
    }



    @override
    void visitEmTerm(EmTerm node)
    {
//#debug
        print('  Length:${node.value} em');
//#end

        _treeStack.last.insert(CssNumber.fromEmTherm(node));
        //super.visitEmTerm(node);
    }

    @override
    void visitNumberTerm(NumberTerm node)
    {
//#debug
      print('  Length:${node.value}');
//#end

      _treeStack.last.insert(CssValue.fromNode(node));
      super.visitNumberTerm(node);
    }

    @override
    void visitLiteralTerm(LiteralTerm node)
    {
//#debug
      print('  Literal:${node.text}');
//#end

      _treeStack.last.insert(CssValue.fromNode(node));
      super.visitLiteralTerm(node);
    }

    @override
    void visitHexColorTerm(HexColorTerm node)
    {


//#debug
      print('  HexColor:${node.text}');
//#end

      _treeStack.last.insert(CssColor.fromHex(node.text));
      super.visitHexColorTerm(node);
    }


    @override
    void visitUnitTerm(UnitTerm node)
    {
//#debug
        print('  Unit:${node.text} ${node.unitToString()}');
//#end

        _treeStack.last.insert(CssNumber.fromUnitTherm(node));
        super.visitUnitTerm(node);
    }


    @override
    void visitFunctionTerm(FunctionTerm node)
    {
//#debug
        print('  Function:${node.text}');
//#end

        var cssFunction = CssFunction(this, _treeStack);

        _treeStack.add(cssFunction);
        super.visitFunctionTerm(node);
        _treeStack.removeLast();

        var name = cssFunction.name;

        if (functions.containsKey(name))
        {
            var f = functions[name];

            var result = ( f != null ) ?f(cssFunction) : null;

            if (result != null)
            {
                _treeStack.last.insert(result);
            }
        }


    }


}



class CssTreeItem
{
    late final Queue<CssTreeItem> _treeStack;
    late final CssDecode decoder;

    CssTreeItem(this.decoder,this._treeStack);

    void insert(Object child)
    {

    }

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


    CssRuleSet(CssDecode decoder,Queue<CssTreeItem> treeStack) : super(decoder,treeStack);

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
        }
    }

    @override
    String toString()
    {
        final builder = StringBuffer();
        var firstSelector = true;

        for(var selector in selectors)
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


        return builder.toString();
    }

}

class CssSelector extends CssTreeItem
{
    CssSimpleSelector? first;
    var selectors = <CssSimpleSelector>[];

    CssSelector(CssDecode decoder, Queue<CssTreeItem> treeStack) : super(decoder, treeStack);

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
            first!.text = (child as Identifier).name;
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

    CssDeclaration(CssDecode decoder, Queue<CssTreeItem> treeStack) : super(decoder, treeStack)
    {
        _ruleSet = treeStack.last as CssRuleSet;
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

    CssFunction(CssDecode decoder, Queue<CssTreeItem> treeStack) : super(decoder, treeStack);

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

class CssValue
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

        return CssValue();
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

          unit  = 'em';
      }


      double valueSat(double min, double max)
      {
          return value<min ? min : value>max ? max : value;
      }

      int valueInt(int min,int max)
      {
          return valueSat(min.toDouble(),max.toDouble()).toInt();
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

class CssInherited extends CssValue
{

}

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


class CssColor extends CssValue
{
    int red = 0;
    int green = 0;
    int blue = 0;
    int alpha = 255;

    CssColor.fromRgba(this.red,this.green,this.blue,this.alpha);

    CssColor.fromHex(String hexColor)
    {
      var t = hexColor;

      switch (t.length)
      {
          case 3:
            t = t.substring(0,1)+t.substring(0,1)+t.substring(1,2)+t.substring(1,2)+t.substring(2,3)+t.substring(2,3)+'ff';
            break;
          case 4:
            t = t.substring(0,1)+t.substring(0,1)+t.substring(1,2)+t.substring(1,2)+t.substring(2,3)+t.substring(2,3)+
                t.substring(3,4)+t.substring(3,4);
            break;
          case 6:
            t = t+'ff';
            break;
          case 8:
            break;
          default:
            t = '000000ff';
      }

        red = int.parse(t.substring(0,2),radix: 16);
        green = int.parse(t.substring(2,4),radix: 16);
        blue = int.parse(t.substring(4,6),radix: 16);
        alpha =  int.parse(t.substring(6,8),radix: 16);
    }

    @override
    String toString()
    {
        var result = '#'
            + red.toRadixString(16).padLeft(2,'0')
            + green.toRadixString(16).padLeft(2,'0')
            + blue.toRadixString(16).padLeft(2,'0');

        if (alpha != 0xff) 
        {
            result += alpha.toRadixString(16).padLeft(2,'0');
        }

        return result;
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

    CssSimpleSelector? next;
    String text ='';
    int    type = SELECTOR_ELEMENT;
    int    combinator = COMBINATOR_NONE;


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

        switch(type)
        {
            case SELECTOR_ID:
              tp = '#';
              break;
            case SELECTOR_CLASS:
              tp = '.';
              break;
        }

        return '$comb$tp$text';
    }


}

CssValue? _rgbFunction (CssFunction function)
{
    return CssColor.fromRgba((function.params[0] as CssNumber).valueInt(0,255),
                             (function.params[1] as CssNumber).valueInt(0,255),
                             (function.params[2] as CssNumber).valueInt(0,255),
                             255);
}