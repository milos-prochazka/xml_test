import 'dart:io';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:html/dom.dart';
import 'dart:convert';
import 'package:html/parser.dart' as html;
import 'package:csslib/parser.dart' as css;
import 'package:csslib/visitor.dart';

import 'package:xml/xml.dart';
import 'package:xml_test/epub/CssDecode.dart';
import 'package:xml_test/xml/xnode.dart';

class Epub
{
    // Epub files dictionary
    var files = <String,ArchiveFile>{};

    // Manifest dictionary
    var manifest = <String,ManifestItem>{};

    // Spine List
    var spineList = <ManifestItem>[];

    // Document List
    var documents = <XNode>[];

    // Big docucument (merged documents)
    var bigDocument = XNode.body();

    // Navigation points (short names)
    var shortNavigation = <String,NavigationPoint>{};

    // Navigation points (long names)
    var longNavigation = <String,NavigationPoint>{};

    Epub(Archive archive)
    {
        _loadArchive(archive);
    }

    void _loadArchive(Archive archive)
    {
        for (final file in archive)
        {
            final filename = file.name;
            files[filename] = file;

            if (file.isFile)
            {

                if (filename.endsWith('.opf'))
                {
                    var strText = utf8.decode(file.content as List<int>, allowMalformed: true);
                    _loadOpf(strText);
                }

            }
        }

        for(var cs in manifest.values)
        {
            cs.$$$();
        }

        _loadDocumentFiles();
    }

    /// Loads opf file
    /// - Creates manifest
    /// - Creates spneList (list of document htmls)
    void _loadOpf(String xmlText)
    {
        var doc = XmlDocument.parse(xmlText);
        var opf = XNode.fromXmlDocument(doc);

        // Load manifest
        var manifestNodes = opf.getChildren(['package','manifest'],childNames:  {'item'});

        for(var item in manifestNodes)
        {
            var manfestItem = ManifestItem(item,files);
            if (manfestItem.valid)
            {
                manifest[manfestItem.id] = manfestItem;
            }

            print (manfestItem.toString());
        }

        // Load spine
        var spineNodes = opf.getChildren(['package','spine'],childNames:  {'itemref'});

        for (var itemref in spineNodes)
        {
            var idref = itemref.attributes['idref'];

            if (idref != null && manifest.containsKey(idref))
            {
                spineList.add(manifest[idref]!);
            }
        }
    }

    /// Loads files in the spineList (document content)
    /// - Loads files in the smineList and adds them to the document list.
    void _loadDocumentFiles()
    {
        for(var item in spineList)
        {
            bigDocument.children.add(XNode.comment('\r\n --- ${item.id} (${item.file.name}) --\r\n'));
            var node = item.xmlNode;
            var body = node.getChildren(['html','body']);
            var first = true;

            for (var node in body)
            {
                _navigation(item.file.name, node, first);
                first = false;
                bigDocument.children.add(node);
            }
            documents.add(node);
        }
    }

    void _navigation(String docId,XNode node,bool firstNode)
    {
        node.linkedData['docId'] = docId;

        if (firstNode)
        {
            _addNavigationPoint(node,NavigationPoint('', docId, node));
        }

        var id = node.attributes['id'];
        if (id != null)
        {
            _addNavigationPoint(node,NavigationPoint(id, docId, node));
        }

        for(var child in node.children)
        {
            _navigation(docId, child, false);
        }
    }

    void _addNavigationPoint(XNode node,NavigationPoint navPoint)
    {
        node.linkedData['longNavigation'] = navPoint;
        if (navPoint.id != '')
        {
            node.linkedData['shortNavigation'] = navPoint;
            shortNavigation['#'+navPoint.id] = navPoint;
            longNavigation[navPoint.file+'#'+navPoint.id] = navPoint;
        }
        else
        {
          longNavigation[navPoint.file] = navPoint;
        }
    }

}

class ManifestItem
{
    late String href;
    late String id;
    late String media_type;
    late ArchiveFile file;

    XNode? _xmlNode;
    List<int>? _bytes;

    bool valid = false;

    static final mimeRegex = RegExp(r'(?<=[\/\+])[\w\-\.]+');

    ManifestItem(XNode item,Map<String,ArchiveFile> files)
    {
        final _href = item.attributes['href'];
        final _id = item.attributes['id'];
        final _media_type = item.attributes['media-type'] ?? '';

        if (_href != null && _id != null)
        {
            if (files.containsKey(_href))
            {
              href = _href;
              id = _id;
              media_type = _media_type;
              file = files[_href]!;
              valid = true;

              var types = mimeTypes;
            }
        }
    }

    Set<String> get mimeTypes
    {
        var result = <String>{};

        var matches = mimeRegex.allMatches(media_type);

        for (var match in matches)
        {
            var str = match.input.substring(match.start,match.end);
            if (!result.contains(str))
            {
                result.add(str);
            }
        }
        return result;
    }

    List<int> get bytes
    {
        _bytes ??= file.content as List<int>;
        return _bytes as List<int>;
    }

    XNode get xmlNode
    {
        var mime = mimeTypes;

        if (_xmlNode == null)
        {
            if (mime.containsAll(['html','xhtml']))
            {
                var strText = utf8.decode(bytes);
                _xmlNode = XNode.fromHtmlDocument(html.parse(strText));
            }
            else if (mime.contains('xml'))
            {
                var strText = utf8.decode(bytes);
                _xmlNode = XNode.fromXmlDocument(XmlDocument.parse(strText));
            }
            else
            {
                _xmlNode = XNode();
            }

        }

        return _xmlNode as XNode;
    }

    void $$$ ()
    {
        var mime = mimeTypes;

        if (mime.contains('css'))
        {
            // var strText = utf8.decode(bytes).replaceAll('1em', '3.3mm');
            var strText = 'h1,p.prvni.druha { color: #fb8ca8ec; }';
            var stylesheet = css.parse(strText);
            var qq = stylesheet.topLevels[0];
            var debug = stylesheet.toDebugString();
            File('out/list${file.name}')
                ..createSync(recursive: true)
                ..writeAsBytesSync(utf8.encode(debug));


            var jj = qq.span;

            print(jj.toString());

            var cs = CssDecode(strText);



            var brk = 1;
        }

    }



    @override
    String toString()
    {
        return (valid) ?
                  'id:$id media-type:$media_type href:$href' :
                  'invalid';
    }
}

class NavigationPoint
{
    late String id;
    late String file;
    late XNode  node;
    bool    reference = false;
    var     linkedData = <String,dynamic>{};

    NavigationPoint(this.id,this.file,this.node);

    @override
    String toString()
    {
        return 'id:$id file:$file reference:$reference';
    }
}