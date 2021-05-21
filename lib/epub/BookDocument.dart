import 'package:archive/src/archive.dart';
import 'package:xml_test/epub/epub.dart';
import 'package:xml_test/xml/xnode.dart';
import 'package:xml_test/common.dart';

class BookDocument extends Epub
{
      // Big docucument (merged documents)
    var bookDocument = XNode.body();
    var textWriter = StringBuffer();


    BookDocument(Archive archive) : super(archive);

    void makeDocument()
    {
        bookDocument = XNode.body();
        textWriter.clear();

        for (var tag in bigDocument.children)
        {
            _makeTag(tag);
        }
    }

    void _makeTag(XNode node)
    {
        switch  (node.type)
        {
            case XNode.TEXT:
                if (textWriter.isEmpty || !isBlankOrNull(node.text))
                {
                    textWriter.write(node.text);
                }
                break;

            case XNode.ELEMENT:
              switch (node.name)
              {
                  case 'div':
                  case 'p':
                    if (textWriter.isNotEmpty)
                    {
                        var para = XNode(type:XNode.ELEMENT,name:'p',
                                        children: [XNode.text(textWriter.toString().trim())]);
                        bookDocument.children.add(para);
                        textWriter.clear();
                    }

                    for (var child in node.children)
                    {
                        _makeTag(child);
                    }

                    if (textWriter.isNotEmpty)
                    {
                         var para = XNode(type:XNode.ELEMENT,name:'p',
                                        children: [XNode.text(textWriter.toString().trim())]);
                        bookDocument.children.add(para);
                        textWriter.clear();
                    }
                    break;

                  default:
                    for (var child in node.children)
                    {
                        _makeTag(child);
                    }
                    break;
              }
        }
    }

}