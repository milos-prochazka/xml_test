import 'dart:io';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'dart:convert';

import 'package:xml/xml.dart';
import 'package:xml_test/xml/xnode.dart';

class Epub 
{
    // Epub files dictionary
    var files = <String,ArchiveFile>{};

    // Manifest dictionary
    var manifest = <String,ManifestItem>{};

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
    }

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
    }
}

class ManifestItem
{
    late String href;
    late String id;
    late String media_type;
    late ArchiveFile file;

    bool valid = false;

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
            }
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
