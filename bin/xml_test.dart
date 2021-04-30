import 'package:xml/xml.dart';
import 'package:html/parser.dart' as html;
import 'package:html/dom.dart';
import 'package:xml_test/common.dart';
import 'package:xml_test/epub/epub.dart';
import 'package:xml_test/xml/xnode.dart';

import 'dart:io';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'dart:convert';

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

void test1(List<String> arguments) 
{
    var blank = isBlankOrNull('     \r\n\u200F');

  var htmlDoc = html.parse(
      '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd"><html><BOdy><!-- komentar --> Hello &amp; a&#768; world! <hr><a href="www.html5rocks.com">HTML5 rocks!</a><h1>HEAD1');

    htmlDoc.body!.children.insert(1, Element.tag('br'));
    print(htmlDoc.outerHtml);
    print('----s------------------------------------------');

    var nd = XNode.fromHtmlDocument(htmlDoc);

    var qq = toNullableType<String>(nd);

    print(nd.toHtmlDocument().outerHtml);

    htmlDoc = html.parse('');
    var body = htmlDoc.body!;
    body.append(Element.html('<a href="qaqa.html">QAQA</a>'));

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
    builder.declaration(attributes: {'ajaa': 'paja'});
    builder.element('bookshelf', nest: () 
    {
        builder.cdata('32723237832787');
        builder.namespace('http://qqqq.qaqa');
        builder.namespace('http://zozo.xul', 'dx');
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
            builder.element('dx:price', nest: 39.95);
        });
        builder.element('price', nest: 132.00);
    });
    final bookXml = builder.buildDocument();
    var ndx = XNode.fromXmlDocument(bookXml);
    print(ndx.toXmlDocument().toXmlString(pretty: true, indent: '  '));

    print('----------------------------------------------');
    print(bookXml.toXmlString(pretty: true, indent: '   '));
    for (var ch in document.rootElement.children) 
    {
        var named = toNullableType<XmlHasName>(ch);
        var text = toNullableType<XmlText>(ch);

        if (named != null) 
        {
            print(named.name.local);
        }
        if (text != null && text.text != '') 
        {
            print('"${text.text.replaceAll('\r', '').replaceAll('\n', '').trim()}"');
        }
    }

    print('----------------------------------------------');
}

void main(List<String> arguments) 
{
    final bytes = File('test.epub').readAsBytesSync();

    // Decode the Zip file
    final archive = ZipDecoder().decodeBytes(bytes);

    var epub = Epub(archive);

    // Extract the contents of the Zip archive to disk.
    for (final file in archive) 
    {
        final filename = file.name;

        if (file.isFile) 
        {
            final data = file.content as List<int>;
            File('out/' + filename)
                ..createSync(recursive: true)
                ..writeAsBytesSync(data);

            if (filename.endsWith('.opf')) 
            {
                var strText = utf8.decode(data, allowMalformed: true);
                var doc = XmlDocument.parse(strText);
                var xn = XNode.fromXmlDocument(doc);
            }
        } 
        else 
        {
            Directory('out/' + filename)..create(recursive: true);
        }
    }
}
