
import 'package:csslib/parser.dart' as css;
import 'package:csslib/visitor.dart';


class CssDecode extends Visitor
{
    CssDecode(String cssText)
    {
        var stylesheet = css.parse(cssText);

        stylesheet.visit(this);
    }


    @override
    void visitIdentifier(Identifier node)
    {
      print ('Identifier: ${node.name}');
      super.visitIdentifier(node);
    }

    @override
    void visitLengthTerm(LengthTerm node)
    {
      print('  Length:${node.value} ${node.unitToString()}');
      super.visitLengthTerm(node);
    }

    @override
    void visitEmTerm(EmTerm node)
    {
      print('  Length:${node.value} em');
      super.visitEmTerm(node);
    }

    @override
    void visitNumberTerm(NumberTerm node)
    {
      print('  Length:${node.value}');
      super.visitNumberTerm(node);
    }

    @override
    void visitLiteralTerm(LiteralTerm node)
    {
      print('  Literal:${node.text}');
      super.visitLiteralTerm(node);
    }

    @override
    void visitFunctionTerm(FunctionTerm node)
    {
      print('  Function:${node.text}');
      super.visitFunctionTerm(node);
    }


}