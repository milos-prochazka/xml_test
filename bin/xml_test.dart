
import 'package:xml/xml.dart';
import 'package:html/parser.dart' as html;
import 'package:html/dom.dart';

// ignore_for_file: unnecessary_cast

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
    static const TEXT_NAME = r'$TEXT$';
    static const COMMENT_NAME = r'$COMMENT$';
    static const DOCTYPE_NAME = r'$DOCTYPE$';
    static const DOCUMENT_NAME = r'$DOCUMENT$';
    static const DECLARATION_NAME = r'$XML$';
    static const CDATA_NAME = r'$CDATA$';

    static const UNKNOWN = 0;
    static const TEXT = 1;
    static const ELEMENT = 2;
    static const COMMENT = 3;
    static const DOCTYPE = 4;
    static const DOCUMENT = 5;
    static const DECLARATION = 6;
    static const CDATA = 6;

    var type     = UNKNOWN;
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
            type = ELEMENT;
        }
        else if (node is XmlText)
        {
            var txt = node as XmlText;
            name = TEXT_NAME;
            text = txt.text;
            type = TEXT;
        }
        else if (node is XmlComment)
        {
            var comment = node as XmlComment;
            name = COMMENT_NAME;
            text = comment.text;
            type = COMMENT;
        }
        else if (node is XmlDocument)
        {
            name = DOCUMENT_NAME;
            type = DOCUMENT;
        }
        else if (node is XmlDeclaration)
        {
            name = DECLARATION_NAME;
            type = DECLARATION;
        }
        else if (node is XmlCDATA)
        {
            var cdata = node as XmlCDATA;
            name = CDATA_NAME;
            text = cdata.text;
            type = CDATA;
        }
        else if (node is XmlDoctype)
        {
            var doctype = node as XmlDoctype;
            name = DOCTYPE_NAME;
            text = doctype.text;
            type = DOCTYPE;
        }
        else
        {
            type = UNKNOWN;
        }


        if (type != UNKNOWN)
        {        
          for (var attribute in node.attributes)
          {
              attrib[attribute.name.local] = attribute.value;
          }
          
          for(var child in node.children)
          {
              var childNode = XNode.fromXmlNode(child);
              if (childNode.type != UNKNOWN)
              {
                  children.add(childNode);
              }
          }
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
      '<body>Hello &amp; a&#768; world! <hr><a href="www.html5rocks.com">HTML5 rocks!</a><h1>HEAD1</h1>');
  htmlDoc.body!.children.insert(1,Element.tag('br'));

  htmlDoc = html.parse('');
  var body = htmlDoc.body!;
  body.append(Element.html('<a href="qaqa.html">QAQA</a>'));
  var chd = CharacterData();
  print(htmlDoc.outerHtml);


  final document = XmlDocument.parse(bookshelfXml);

  print('----------------------------------------------');
  print(document.toString());
  print('----------------------------------------------');
  print(document.toXmlString(pretty: true, indent: '  '));
  print('----------------------------------------------');

  //XNode.fromXmlDocument(document);

  final builder = XmlBuilder();
  //builder.processing('xml', 'version="1.0"');
  builder.declaration(attributes: {'ajaa':'paja'});
  builder.element('bookshelf', nest: () 
  {
    builder.cdata('32723237832787');
    builder.namespace('http://qqqq.qaqa');
    builder.attribute('horkol', 'makovitec');
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
  XNode.fromXmlDocument(bookXml);

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
