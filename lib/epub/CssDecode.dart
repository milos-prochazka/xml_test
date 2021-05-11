
import 'dart:collection';

import 'package:csslib/parser.dart' as css;
import 'package:csslib/visitor.dart';

// ignore_for_file: unnecessary_cast

class CssDecode extends Visitor
{
    final _treeStack = Queue<CssTreeItem>();

    CssDecode(String cssText)
    {
        var stylesheet = css.parse(cssText);

        stylesheet.visit(this);
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

        _treeStack.add(CssRuleSet(this,_treeStack));
        super.visitRuleSet(node);
        _treeStack.removeLast();

    }

    @override
    void visitSelectorGroup(SelectorGroup node)
    {
  //#debug
        print ('SelectorGroup ${node.span!.text}');
  //#end

        var selector = CssSelector(this, _treeStack);
        _treeStack.last.insert(selector);
        _treeStack.add(selector);
        super.visitSelectorGroup(node);
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

        _treeStack.add(CssDeclaration(this, _treeStack));
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

      super.visitLengthTerm(node);
    }



    @override
    void visitEmTerm(EmTerm node)
    {
//#debug
      print('  Length:${node.value} em');
//#end

      super.visitEmTerm(node);
    }

    @override
    void visitNumberTerm(NumberTerm node)
    {
//#debug
      print('  Length:${node.value}');
//#end

      _treeStack.last.insert(node);
      super.visitNumberTerm(node);
    }

    @override
    void visitLiteralTerm(LiteralTerm node)
    {
//#debug
      print('  Literal:${node.text}');
//#end

      _treeStack.last.insert(node);
      super.visitLiteralTerm(node);
    }

    @override
    void visitHexColorTerm(HexColorTerm node)
    {
      var t = node.text;

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

      node.text = t;

//#debug
      print('  HexColor:${node.text}');
//#end

      _treeStack.last.insert(node);
      super.visitHexColorTerm(node);
    }


    @override
    void visitUnitTerm(UnitTerm node)
    {
//#debug
        print('  Unit:${node.text} ${node.unitToString()}');
//#end

        super.visitUnitTerm(node);
    }


    @override
    void visitFunctionTerm(FunctionTerm node)
    {
//#debug
      print('  Function:${node.text}');
//#end

      super.visitFunctionTerm(node);
    }

    @override
    void visitSelector(Selector node)
    {
//#debug
      print('  Selector:${node.span!.text}');
//#end
      super.visitSelector(node);
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


    CssRuleSet(CssDecode decoder,Queue<CssTreeItem> treeStack) : super(decoder,treeStack);

    @override
    void insert(Object child)
    {
        selectors.add(child as CssSelector);
    }
}

class CssSelector extends CssTreeItem
{
    CssSimpleSelector? first;

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
        }
        else if (child is Identifier)
        {
            first!.text = (child as Identifier).name;
        }
    }
}

class CssDeclaration extends CssTreeItem
{
    late CssRuleSet _ruleSet;
    String name = '';

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
    static const SELECTOR_ID = 0;
    static const SELECTOR_CLASS = 1;
    static const SELECTOR_NAMESPACE = 2;

    CssSimpleSelector? next;
    String text ='';
    int    type = SELECTOR_ELEMENT;
    int    combinator = COMBINATOR_NONE;


}