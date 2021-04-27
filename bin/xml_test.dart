import 'package:xml/xml.dart';
//import 'package:xml/xml_events.dart';
import 'package:html/parser.dart' as html;
import 'package:html/dom.dart';

final bookshelfXml = '''<?xml version="1.0"?>
<!DOCTYPE address
[
   <!ELEMENT address (name,company,phone)>
   <!ELEMENT name (#PCDATA)>
   <!ELEMENT company (#PCDATA)>
   <!ELEMENT phone (#PCDATA)>
]>
    <bookshelf>
      Prvni text
      <book>
        <title lang="english">Growing a Language</title>
        <price>29.99</price>
      </book>
      <book>
        <title lang="english">Learning XML</title>
        <price>39.95</price>
      </book>
      <price>132.00</price>
      Obtycejny text
      <!-- comment -->
    </bookshelf>''';


class XNode 
{
    static const COMMENT_NAME = r'$COMMENT$';

    var name     = '';
    var text     = '';
    var children = <XNode>[];
    var attrib   = <String,String>{};


    XNode.fromXmlNode(XmlNode node)
    {
        _fromXmlNode(node);        
    }

    XNode.fromXmlDocument(XmlDocument document) 
    {
        _fromXmlNode(document.root);
    }

    void _fromXmlNode(XmlNode node)
    {
        if (node is XmlElement)
        {
            var element = node as XmlElement;
            name = element.name.local;
        }
        else if (node is XmlComment)
        {
            var comment = node as XmlComment;
            name = COMMENT_NAME;
            text = comment.text;
        }

        
        for (var attribute in node.attributes)
        {
            attrib[attribute.name.local] = attribute.value;
        }
        
        for(var child in node.children)
        {
            children.add(XNode.fromXmlNode(child));
        }

    }
}

T? toType<T>(Object instance)
{
    if (instance is T)
    {
        return instance as T;
    }
    else
    {
        return null;
    }
}

void main(List<String> arguments) 
{
  var htmlDoc = html.parse(
      '<body>Hello world! <hr><a href="www.html5rocks.com">HTML5 rocks!</a><h1>HEAD1</h1>');
  print(htmlDoc.outerHtml);

  final document = XmlDocument.parse(bookshelfXml);

  print('----------------------------------------------');
  print(document.toString());
  print('----------------------------------------------');
  print(document.toXmlString(pretty: true, indent: '  '));
  print('----------------------------------------------');

  XNode.fromXmlDocument(document);

  final builder = XmlBuilder();
  //builder.processing('xml', 'version="1.0"');
  builder.declaration(attributes: {'ajaa':'paja'});
  builder.element('bookshelf', nest: () 
  {
    builder.cdata('32723237832787');
    builder.element('book', nest: () 
    {
      builder.element('title', nest: () 
      {
        builder.attribute('lang', 'en');
        builder.text('Growing a Language');
      });
      builder.element('price', nest: 29.99);
    });
    builder.element('book', nest: () 
    {
      builder.element('title', nest: () 
      {
        builder.attribute('lang', 'en');
        builder.text('Learning XML');
      });
      builder.element('price', nest: 39.95);
    });
    builder.element('price', nest: 132.00);    
  });
  final bookXml = builder.buildDocument();

  print('----------------------------------------------');
  print(bookXml.toXmlString(pretty: true,indent: '   '));
  for(var ch in document.rootElement.children)
  {
      var named  = toType<XmlHasName>(ch);
      var text = toType<XmlText>(ch);

      

      if (named != null)
      {
        print(named.name.local);
      }
      if (text!= null && text.text != '' )
      {
        print('"${text.text.replaceAll('\r', '').replaceAll('\n', '').trim()}"');
      }
  }

  print('----------------------------------------------');


}
