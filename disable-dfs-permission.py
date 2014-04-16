import xml.etree.ElementTree as ET
tree = ET.parse('/etc/hadoop/conf/hdfs-site.xml')
root = tree.getroot()
already = 0
for p in root.iter('name'):
    if p.text == 'dfs.permission':
        already = 1
if already == 0:
    root.append(ET.fromstring('<property>\n    <name>dfs.permission</name>\n    <value>false</value>\n  </property>'))
    tree.write('/etc/hadoop/conf/hdfs-site.xml')

