
import 'dart:collection';

import 'package:csslib/parser.dart' as css;
import 'package:csslib/visitor.dart';


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
    void visitIdentifier(Identifier node)
    {
//#debug
      print ('Identifier: ${node.name}');
//#end
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
      super.visitNumberTerm(node);
    }

    @override
    void visitLiteralTerm(LiteralTerm node)
    {
//#debug
      print('  Literal:${node.text}');
//#end
      super.visitLiteralTerm(node);
    }

    @override
    void visitFunctionTerm(FunctionTerm node)
    {
//#debug
      print('  Function:${node.text}');
//#end
      super.visitFunctionTerm(node);
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
    CssRuleSet(CssDecode decoder,Queue<CssTreeItem> treeStack) : super(decoder,treeStack);
    
}