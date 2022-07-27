<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" xmlns:marc="http://www.loc.gov/MARC21/slim"
    xmlns:bf="http://id.loc.gov/ontologies/bibframe/"
    xmlns:bflc="http://id.loc.gov/ontologies/bflc/" xmlns:madsrdf="http://www.loc.gov/mads/rdf/v1#"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" exclude-result-prefixes="xsl marc">

    <!-- Conversion specs for Process8 -->

    <xsl:template
        match="
            marc:datafield[@tag = '260' or (@tag = '880' and substring(marc:subfield[@code = '6'], 1, 3) = '260')] |
            marc:datafield[@tag = '262'] |
            marc:datafield[@tag = '264' or (@tag = '880' and substring(marc:subfield[@code = '6'], 1, 3) = '264')]"
        mode="instance">

        <!-- 
            This variable looks like:
            <paGroup>
                <type>Publication</type>
                <bf:date rdf:datatype="http://id.loc.gov/datatypes/edtf">1987</bf:date>
                <bf:place rdf:resource="http://id.loc.gov/vocabulary/countries/ja"/>
            </paGroup>
            ...
        -->
        <xsl:variable name="cf008data">
            <xsl:apply-templates select="../marc:controlfield[@tag = '008']" mode="process8"/>
        </xsl:variable>
        <!--<xsl:copy-of select="$cf008data" />-->

        <xsl:variable name="vTag">
            <xsl:choose>
                <xsl:when test="@tag = '880'">
                    <xsl:value-of select="substring(marc:subfield[@code = '6'], 1, 3)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="@tag"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="v880Occurrence">
            <xsl:value-of select="substring(substring-after(marc:subfield[@code = '6'], '-'), 1, 2)"
            />
        </xsl:variable>
        <xsl:variable name="v880Ref">
            <xsl:value-of select="concat($vTag, '-', $v880Occurrence)"/>
        </xsl:variable>

        <!--
            This variable looks like:
            <marc:sfGroup xmlns:marc="http://www.loc.gov/MARC21/slim" tag="264">
                <marc:df tag="880" ind1=" " ind2=" ">
                    <marc:sf code="6">260-02/$1</marc:sf>
                    <marc:sf code="a">[S.l. :</marc:sf>
                    <marc:sf code="b">s.n.,</marc:sf>
                    <marc:sf code="c">昭和 62 i.e. 1987]</marc:sf>
                </marc:df>
                <marc:df tag="264" ind1=" " ind2="1">
                    <marc:sf code="a" gpos="2" pos="2">[S.l. :</marc:sf>
                    <marc:sf code="b" gpos="2" pos="3">s.n.,</marc:sf>
                    <marc:sf code="c" gpos="2" pos="4">Shōwa 62 i.e. 1987]</marc:sf>
                </marc:df>
            </marc:sfGroup>
            ...
        -->
        <xsl:variable name="sfblocks">
            <xsl:call-template name="blockize26x">
                <xsl:with-param name="df" select="self::node()"/>
                <xsl:with-param name="v880Ref" select="$v880Ref"/>
            </xsl:call-template>
        </xsl:variable>
        <!--<xsl:copy-of select="$sfblocks"/>-->

        <xsl:variable name="has880">
            <xsl:choose>
                <xsl:when test="$sfblocks/marc:sfGroup[1]/marc:df[@tag = '880']">
                    <xsl:value-of select="true()"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="false()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="vXmlLang">
            <xsl:apply-templates select="." mode="xmllang"/>
        </xsl:variable>
        <xsl:variable name="vLinkedXmlLang">
            <xsl:if test="$has880">
                <xsl:apply-templates
                    select="../marc:datafield[@tag = '880' and contains(marc:subfield[@code = '6'], $v880Ref)]"
                    mode="xmllang"/>
            </xsl:if>
        </xsl:variable>

        <xsl:for-each select="$sfblocks/marc:sfGroup">
            <xsl:variable name="sfgTag" select="@tag"/>
            <xsl:variable name="df" select="marc:df[@tag = $sfgTag]"/>
            <xsl:variable name="ind2val" select="$df/@ind2"/>
            <xsl:variable name="vProvisionActivity">
                <xsl:choose>
                    <xsl:when test="$ind2val = '0'">Production</xsl:when>
                    <xsl:when test="$ind2val = '1'">Publication</xsl:when>
                    <xsl:when test="$ind2val = '2'">Distribution</xsl:when>
                    <xsl:when test="$ind2val = '3'">Manufacture</xsl:when>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="vStatement">
                <xsl:apply-templates select="$df/marc:sf[@code = 'a' or @code = 'b' or @code = 'c']"
                    mode="concat-nodes-delimited"/>
            </xsl:variable>
            <xsl:variable name="vLinkedStatement">
                <xsl:if test="marc:df[@tag = '880']">
                    <xsl:apply-templates
                        select="marc:df[@tag = '880']/marc:sf[@code = 'a' or @code = 'b' or @code = 'c']"
                        mode="concat-nodes-delimited"/>
                </xsl:if>
            </xsl:variable>
            <xsl:choose>
                <xsl:when test="$serialization = 'rdfxml'">
                    <xsl:choose>
                        <xsl:when test="$sfgTag = '264' and $df/@ind2 = '4'">
                            <xsl:choose>
                                <xsl:when test="$cf008data/paGroup[type = 'Copyright']">
                                    <xsl:copy-of
                                        select="$cf008data/paGroup[type = 'Copyright']/bf:*"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <bf:copyrightDate>
                                        <xsl:if test="$vXmlLang != ''">
                                            <xsl:attribute name="xml:lang">
                                                <xsl:value-of select="$vXmlLang"/>
                                            </xsl:attribute>
                                        </xsl:if>
                                        <xsl:call-template name="tChopPunct">
                                            <xsl:with-param name="pString" select="$vStatement"/>
                                        </xsl:call-template>
                                    </bf:copyrightDate>
                                    <xsl:if test="$vLinkedStatement != ''">
                                        <bf:copyrightDate>
                                            <xsl:if test="$vLinkedXmlLang != ''">
                                                <xsl:attribute name="xml:lang">
                                                  <xsl:value-of select="$vLinkedXmlLang"/>
                                                </xsl:attribute>
                                            </xsl:if>
                                            <xsl:call-template name="tChopPunct">
                                                <xsl:with-param name="pString"
                                                  select="$vLinkedStatement"/>
                                            </xsl:call-template>
                                        </bf:copyrightDate>
                                    </xsl:if>
                                </xsl:otherwise>

                            </xsl:choose>
                        </xsl:when>
                        <xsl:otherwise>
                            <bf:provisionActivity>
                                <bf:ProvisionActivity>
                                    <xsl:if test="$vProvisionActivity != ''">
                                        <rdf:type>
                                            <xsl:attribute name="rdf:resource">
                                                <xsl:value-of
                                                  select="concat($bf, $vProvisionActivity)"/>
                                            </xsl:attribute>
                                        </rdf:type>
                                        <xsl:if
                                            test="not(preceding-sibling::marc:sfGroup) or preceding-sibling::marc:sfGroup/marc:df[@tag = $sfgTag and @ind2 != $ind2val]">
                                            <xsl:copy-of
                                                select="$cf008data/paGroup[type = $vProvisionActivity]/bf:*"
                                            />
                                        </xsl:if>
                                    </xsl:if>
                                    <xsl:if test="$df/@ind1 = '3'">
                                        <bf:status>
                                            <bf:Status>
                                                <rdfs:label>current</rdfs:label>
                                            </bf:Status>
                                        </bf:status>
                                    </xsl:if>
                                    <xsl:choose>
                                        <xsl:when test="$has880">
                                            <xsl:apply-templates select="marc:subfield[@code = '3']"
                                                mode="subfield3">
                                                <xsl:with-param name="serialization"
                                                  select="$serialization"/>
                                            </xsl:apply-templates>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:apply-templates
                                                select="marc:subfield[@code = '3'] | ../marc:datafield[@tag = '880' and substring(marc:subfield[@code = '6'], 1, 3) = $vTag and substring(substring-after(marc:subfield[@code = '6'], '-'), 1, 2) = $v880Occurrence]/marc:subfield[@code = '3']"
                                                mode="subfield3">
                                                <xsl:with-param name="serialization"
                                                  select="$serialization"/>
                                            </xsl:apply-templates>
                                        </xsl:otherwise>
                                    </xsl:choose>

                                    <xsl:for-each select="$df/marc:sf[@code = 'a']">
                                        <xsl:variable name="sfPos" select="@pos"/>
                                        <xsl:variable name="vLabel">
                                            <xsl:call-template name="tChopPunct">
                                                <xsl:with-param name="pString" select="."/>
                                            </xsl:call-template>
                                        </xsl:variable>
                                        <xsl:variable name="vLinkedLabel">
                                            <xsl:if test="$has880">
                                                <xsl:call-template name="tChopPunct">
                                                  <xsl:with-param name="pString"
                                                  select="$df/../marc:df[@tag = '880']/marc:sf[position() = $sfPos]"
                                                  />
                                                </xsl:call-template>
                                            </xsl:if>
                                        </xsl:variable>
                                        <bflc:simplePlace>
                                            <xsl:if test="$vXmlLang != ''">
                                                <xsl:attribute name="xml:lang">
                                                  <xsl:value-of select="$vXmlLang"/>
                                                </xsl:attribute>
                                            </xsl:if>
                                            <xsl:value-of select="$vLabel"/>
                                        </bflc:simplePlace>
                                        <xsl:if test="$vLinkedLabel != ''">
                                            <bflc:simplePlace>
                                                <xsl:if test="$vLinkedXmlLang != ''">
                                                  <xsl:attribute name="xml:lang">
                                                  <xsl:value-of select="$vLinkedXmlLang"/>
                                                  </xsl:attribute>
                                                </xsl:if>
                                                <xsl:value-of select="$vLinkedLabel"/>
                                            </bflc:simplePlace>
                                        </xsl:if>
                                    </xsl:for-each>
                                    <xsl:for-each select="$df/marc:sf[@code = 'b']">
                                        <xsl:variable name="sfPos" select="@pos"/>
                                        <xsl:variable name="vLabel">
                                            <!-- detect if there are unmatched brackets in preceding or following subfield -->
                                            <xsl:variable name="vAddBrackets"
                                                select="
                                                    (not(contains(., '[')) and
                                                    not(contains(., ']')) and
                                                    ((contains(preceding-sibling::marc:sf[@code = 'a'][1], '[') and
                                                    not(contains(preceding-sibling::marc:sf[@code = 'a'][1], ']'))) or
                                                    (contains(following-sibling::marc:sf[@code = 'c'][1], ']') and
                                                    not(contains(following-sibling::marc:sf[@code = 'c'][1], '['))))) = true()"/>
                                            <xsl:call-template name="tChopPunct">
                                                <xsl:with-param name="pString" select="."/>
                                                <xsl:with-param name="pAddBrackets"
                                                  select="$vAddBrackets"/>
                                            </xsl:call-template>
                                        </xsl:variable>
                                        <xsl:variable name="vLinkedLabel">
                                            <xsl:if test="$has880">
                                                <!-- detect if there are unmatched brackets in preceding or following subfield -->
                                                <xsl:variable name="vAddBrackets"
                                                  select="
                                                        (not(contains(../../marc:df[@tag = '880' and substring(marc:sf[@code = '6'], 1, 3) = $vTag and substring(substring-after(marc:sf[@code = '6'], '-'), 1, 2) = $v880Occurrence]/marc:sf[@code = 'b'][position()], '[')) and
                                                        not(contains(../../marc:df[@tag = '880' and substring(marc:sf[@code = '6'], 1, 3) = $vTag and substring(substring-after(marc:sf[@code = '6'], '-'), 1, 2) = $v880Occurrence]/marc:sf[@code = 'b'][position()], ']')) and
                                                        ((contains(../../marc:df[@tag = '880' and substring(marc:sf[@code = '6'], 1, 3) = $vTag and substring(substring-after(marc:sf[@code = '6'], '-'), 1, 2) = $v880Occurrence]/marc:sf[@code = 'b'][position()]/preceding-sibling::marc:sf[@code = 'a'][1], '[') and
                                                        not(contains(../../marc:df[@tag = '880' and substring(marc:sf[@code = '6'], 1, 3) = $vTag and substring(substring-after(marc:sf[@code = '6'], '-'), 1, 2) = $v880Occurrence]/marc:sf[@code = 'b'][position()]/preceding-sibling::marc:sf[@code = 'a'][1], ']'))) or
                                                        (contains(../../marc:df[@tag = '880' and substring(marc:sf[@code = '6'], 1, 3) = $vTag and substring(substring-after(marc:sf[@code = '6'], '-'), 1, 2) = $v880Occurrence]/marc:sf[@code = 'b'][position()]/following-sibling::marc:sf[@code = 'c'][1], ']') and
                                                        not(contains(../../marc:df[@tag = '880' and substring(marc:sf[@code = '6'], 1, 3) = $vTag and substring(substring-after(marc:sf[@code = '6'], '-'), 1, 2) = $v880Occurrence]/marc:sf[@code = 'b'][position()]/following-sibling::marc:sf[@code = 'c'][1], '['))))) = true()"/>
                                                <xsl:call-template name="tChopPunct">
                                                  <xsl:with-param name="pString"
                                                  select="$df/../marc:df[@tag = '880']/marc:sf[position() = $sfPos]"/>
                                                  <xsl:with-param name="pAddBrackets"
                                                  select="$vAddBrackets"/>
                                                </xsl:call-template>
                                            </xsl:if>
                                        </xsl:variable>
                                        <bflc:simpleAgent>
                                            <xsl:if test="$vXmlLang != ''">
                                                <xsl:attribute name="xml:lang">
                                                  <xsl:value-of select="$vXmlLang"/>
                                                </xsl:attribute>
                                            </xsl:if>
                                            <xsl:value-of select="$vLabel"/>
                                        </bflc:simpleAgent>
                                        <xsl:if test="$vLinkedLabel != ''">
                                            <bflc:simpleAgent>
                                                <xsl:if test="$vLinkedXmlLang != ''">
                                                  <xsl:attribute name="xml:lang">
                                                  <xsl:value-of select="$vLinkedXmlLang"/>
                                                  </xsl:attribute>
                                                </xsl:if>
                                                <xsl:value-of select="$vLinkedLabel"/>
                                            </bflc:simpleAgent>
                                        </xsl:if>
                                    </xsl:for-each>
                                    <xsl:for-each select="$df/marc:sf[@code = 'c']">
                                        <xsl:variable name="sfPos" select="@pos"/>
                                        <xsl:variable name="vLabel">
                                            <xsl:call-template name="tChopPunct">
                                                <xsl:with-param name="pString" select="."/>
                                            </xsl:call-template>
                                        </xsl:variable>
                                        <xsl:variable name="vLinkedLabel">
                                            <xsl:if test="$has880">
                                                <xsl:call-template name="tChopPunct">
                                                  <xsl:with-param name="pString"
                                                  select="$df/../marc:df[@tag = '880']/marc:sf[position() = $sfPos]"
                                                  />
                                                </xsl:call-template>
                                            </xsl:if>
                                        </xsl:variable>
                                        <bflc:simpleDate>
                                            <xsl:if test="$vXmlLang != ''">
                                                <xsl:attribute name="xml:lang">
                                                  <xsl:value-of select="$vXmlLang"/>
                                                </xsl:attribute>
                                            </xsl:if>
                                            <xsl:value-of select="$vLabel"/>
                                        </bflc:simpleDate>
                                        <xsl:if test="$vLinkedLabel != ''">
                                            <bflc:simpleDate>
                                                <xsl:if test="$vLinkedXmlLang != ''">
                                                  <xsl:attribute name="xml:lang">
                                                  <xsl:value-of select="$vLinkedXmlLang"/>
                                                  </xsl:attribute>
                                                </xsl:if>
                                                <xsl:value-of select="$vLinkedLabel"/>
                                            </bflc:simpleDate>
                                        </xsl:if>
                                    </xsl:for-each>
                                </bf:ProvisionActivity>
                            </bf:provisionActivity>
                        </xsl:otherwise>
                    </xsl:choose>

                    <xsl:if test="$vTag = '260'">
                        <xsl:for-each select="marc:subfield[@code = 'd']">
                            <xsl:variable name="vLinkedValue">
                                <xsl:if test="$v880Occurrence and $v880Occurrence != '00'">
                                    <xsl:value-of
                                        select="../../marc:datafield[@tag = '880' and substring(marc:subfield[@code = '6'], 1, 3) = $vTag and substring(substring-after(marc:subfield[@code = '6'], '-'), 1, 2) = $v880Occurrence]/marc:subfield[@code = 'd'][position()]"
                                    />
                                </xsl:if>
                            </xsl:variable>
                            <bf:identifiedBy>
                                <bf:PublisherNumber>
                                    <rdf:value>
                                        <xsl:value-of select="."/>
                                    </rdf:value>
                                    <xsl:if test="$vLinkedValue != ''">
                                        <rdf:value>
                                            <xsl:value-of select="$vLinkedValue"/>
                                        </rdf:value>
                                    </xsl:if>
                                </bf:PublisherNumber>
                            </bf:identifiedBy>
                        </xsl:for-each>
                    </xsl:if>
                </xsl:when>
            </xsl:choose>
        </xsl:for-each>

    </xsl:template>

    <xsl:template name="blockize26x">
        <xsl:param name="df"/>
        <xsl:param name="vXmlLang"/>
        <xsl:param name="v880Ref"/>
        <xsl:param name="vLinkedXmlLang"/>

        <!-- Parse the subfields in this datafield. -->
        <xsl:variable name="parsedSfs">
            <xsl:call-template name="parse26x">
                <xsl:with-param name="df" select="$df"/>
                <xsl:with-param name="gpos" select="1"/>
                <xsl:with-param name="pos" select="1"/>
            </xsl:call-template>
        </xsl:variable>

        <!-- Find the group numbers. -->
        <xsl:variable name="groups">
            <xsl:for-each select="$parsedSfs/marc:sf">
                <xsl:variable name="g" select="@gpos"/>
                <xsl:choose>
                    <xsl:when test="count(preceding::marc:sf) = 0">
                        <group>
                            <xsl:value-of select="$g"/>
                        </group>
                    </xsl:when>
                    <xsl:when test="preceding::marc:sf[1][@gpos != $g]">
                        <group>
                            <xsl:value-of select="$g"/>
                        </group>
                    </xsl:when>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>

        <!-- If this datafield has a corresponding 880, extract it. -->
        <xsl:variable name="df880">
            <xsl:if test="$df/marc:subfield[@code = '6']">
                <xsl:variable name="related880">
                    <xsl:copy-of
                        select="$df/../marc:datafield[@tag = '880' and contains(marc:subfield[@code = '6'], $v880Ref)]"
                    />
                </xsl:variable>
                <marc:df>
                    <xsl:copy-of select="$related880/marc:datafield/@*"/>
                    <xsl:for-each select="$related880/marc:datafield/marc:subfield">
                        <marc:sf>
                            <xsl:copy-of select="@*"/>
                            <xsl:copy-of select="text()"/>
                        </marc:sf>
                    </xsl:for-each>
                </marc:df>
            </xsl:if>
        </xsl:variable>

        <!-- Take parsed subfields and related 880, if there is one, and generate groups. -->
        <xsl:for-each select="$groups/group">
            <xsl:variable name="g" select="."/>
            <marc:sfGroup tag="264">
                <xsl:copy-of select="$df880"/>
                <marc:df tag="264">
                    <xsl:copy-of select="$df/@ind1"/>
                    <xsl:attribute name="ind2">
                        <xsl:choose>
                            <xsl:when
                                test="$parsedSfs/marc:sf[@gpos = $g][1][@code = 'e' or @code = 'f' or @code = 'g']"
                                >3</xsl:when>
                            <xsl:when test="$df/@tag = '264'">
                                <xsl:value-of select="$df/@ind2"/>
                            </xsl:when>
                            <xsl:otherwise>1</xsl:otherwise>
                        </xsl:choose>
                    </xsl:attribute>
                    <xsl:for-each select="$parsedSfs/marc:sf[@gpos = $g]">
                        <xsl:copy-of select="."/>
                    </xsl:for-each>
                </marc:df>
            </marc:sfGroup>
        </xsl:for-each>

    </xsl:template>

    <!-- 
        Recursively parse a 26x, subfield by subfield.
        This makes all 26x a 264.
        This template determines which group a subfield goes in based on the Spec's process instructions.
        It adds a group number to each, which is group-ized later.
    -->
    <xsl:template name="parse26x">
        <xsl:param name="df"/>
        <xsl:param name="pos"/>
        <xsl:param name="gpos"/>

        <xsl:variable name="sf" select="$df/marc:subfield[$pos]"/>

        <xsl:if test="$sf/@code = 'a' or $sf/@code = 'b' or $sf/@code = 'c'">
            <marc:sf>
                <xsl:copy-of select="$sf/@*"/>
                <xsl:attribute name="gpos">
                    <xsl:value-of select="$gpos"/>
                </xsl:attribute>
                <xsl:attribute name="pos">
                    <xsl:value-of select="$pos"/>
                </xsl:attribute>
                <xsl:copy-of select="$sf/text()"/>
            </marc:sf>
        </xsl:if>
        <xsl:if test="$sf/@code = 'e' or $sf/@code = 'f' or $sf/@code = 'g'">
            <xsl:variable name="map260sfs">
                <m sfCode="e">a</m>
                <m sfCode="f">b</m>
                <m sfCode="g">c</m>
            </xsl:variable>
            <marc:sf>
                <xsl:attribute name="code">
                    <xsl:value-of select="$map260sfs/m[@sfCode = $sf/@code]"/>
                </xsl:attribute>
                <xsl:attribute name="gpos">
                    <xsl:value-of select="$gpos"/>
                </xsl:attribute>
                <xsl:attribute name="pos">
                    <xsl:value-of select="$pos"/>
                </xsl:attribute>
                <xsl:copy-of select="$sf/text()"/>
            </marc:sf>
        </xsl:if>

        <xsl:variable name="next_gpos" select="$gpos + 1"/>
        <xsl:variable name="next_pos" select="$pos + 1"/>

        <xsl:choose>
            <xsl:when
                test="$df/marc:subfield[$next_pos][@code = 'b' or @code = 'c' or @code = 'f' or @code = 'g']">
                <xsl:call-template name="parse26x">
                    <xsl:with-param name="df" select="$df"/>
                    <xsl:with-param name="gpos" select="$gpos"/>
                    <xsl:with-param name="pos" select="$next_pos"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when
                test="
                    ($sf/@code = 'a' and $df/marc:subfield[$next_pos][@code = 'a'])
                    or
                    ($sf/@code = 'e' and $df/marc:subfield[$next_pos][@code = 'e'])">
                <xsl:call-template name="parse26x">
                    <xsl:with-param name="df" select="$df"/>
                    <xsl:with-param name="gpos" select="$gpos"/>
                    <xsl:with-param name="pos" select="$next_pos"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when
                test="
                    ($sf/@code != 'a' and $df/marc:subfield[$next_pos][@code = 'a'])
                    or
                    ($sf/@code != 'e' and $df/marc:subfield[$next_pos][@code = 'e'])">
                <xsl:call-template name="parse26x">
                    <xsl:with-param name="df" select="$df"/>
                    <xsl:with-param name="gpos" select="$next_gpos"/>
                    <xsl:with-param name="pos" select="$next_pos"/>
                </xsl:call-template>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="marc:controlfield[@tag = '008']" mode="process8">
        <xsl:variable name="vDate1">
            <xsl:choose>
                <xsl:when test="substring(., 8, 4) = '    '"/>
                <xsl:when test="substring(., 8, 4) = '||||'"/>
                <xsl:otherwise>
                    <xsl:value-of select="substring(., 8.4)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="vDate2">
            <xsl:choose>
                <xsl:when test="substring(., 12, 4) = '    '"/>
                <xsl:when test="substring(., 12, 4) = '||||'"/>
                <xsl:otherwise>
                    <xsl:value-of select="substring(., 12, 4)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="provisionDate">
            <xsl:choose>
                <xsl:when test="substring(., 7, 1) = 'c'">
                    <xsl:call-template name="u2x">
                        <xsl:with-param name="dateString" select="concat(substring(., 8, 4), '/..')"
                        />
                    </xsl:call-template>
                </xsl:when>
                <xsl:when
                    test="
                        substring(., 7, 1) = 'd' or
                        substring(., 7, 1) = 'i' or
                        substring(., 7, 1) = 'k' or
                        substring(., 7, 1) = 'm' or
                        substring(., 7, 1) = 'q' or
                        substring(., 7, 1) = 'u' or
                        (substring(., 7, 1) = '|' and $vDate1 != '' and $vDate2 != '')">
                    <xsl:call-template name="u2x">
                        <xsl:with-param name="dateString"
                            select="concat(substring(., 8, 4), '/', substring(., 12, 4))"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:when
                    test="
                        substring(., 7, 1) = 'e' or
                        (substring(., 7, 1) = '|' and $vDate1 != '' and $vDate2 != '')">
                    <xsl:choose>
                        <xsl:when test="substring(., 14, 2) = '  '">
                            <xsl:call-template name="u2x">
                                <xsl:with-param name="dateString"
                                    select="concat(substring(., 8, 4), '-', substring(., 12, 2))"/>
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:call-template name="u2x">
                                <xsl:with-param name="dateString"
                                    select="concat(substring(., 8, 4), '-', substring(., 12, 2), '-', substring(., 14, 2))"
                                />
                            </xsl:call-template>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:when
                    test="
                        substring(., 7, 1) = 'p' or
                        substring(., 7, 1) = 'r' or
                        substring(., 7, 1) = 's' or
                        substring(., 7, 1) = 't' or
                        (substring(., 7, 1) = '|' and $vDate1 != '')">
                    <xsl:call-template name="u2x">
                        <xsl:with-param name="dateString" select="substring(., 8, 4)"/>
                    </xsl:call-template>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="pubPlace">
            <xsl:choose>
                <xsl:when test="substring(., 18, 1) = ' '">
                    <xsl:value-of select="substring(., 16, 2)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="substring(., 16, 3)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="$provisionDate != ''">
                <paGroup>
                    <xsl:choose>
                        <xsl:when
                            test="
                                substring(., 7, 1) = 'c' or
                                substring(., 7, 1) = 'd' or
                                substring(., 7, 1) = 'e' or
                                substring(., 7, 1) = 'm' or
                                substring(., 7, 1) = 'q' or
                                substring(., 7, 1) = 'r' or
                                substring(., 7, 1) = 's' or
                                substring(., 7, 1) = 't' or
                                substring(., 7, 1) = 'u' or
                                substring(., 7, 1) = '|'">
                            <type>Publication</type>
                        </xsl:when>
                        <xsl:when
                            test="
                                substring(., 7, 1) = 'i' or
                                substring(., 7, 1) = 'k'">
                            <type>Production</type>
                            <bf:note>
                                <bf:Note>
                                    <xsl:choose>
                                        <xsl:when test="substring(., 7, 1) = 'i'">
                                            <rdfs:label>inclusive collection dates</rdfs:label>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <rdfs:label>bulk collection dates</rdfs:label>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </bf:Note>
                            </bf:note>
                        </xsl:when>
                        <xsl:when test="substring(., 7, 1) = 'p'">
                            <type>Distribution</type>
                        </xsl:when>
                    </xsl:choose>
                    <bf:date>
                        <xsl:attribute name="rdf:datatype">
                            <xsl:value-of select="concat($edtf, 'edtf')"/>
                        </xsl:attribute>
                        <xsl:value-of select="$provisionDate"/>
                    </bf:date>
                    <xsl:choose>
                        <xsl:when test="substring(., 7, 1) = 'c'">
                            <bf:status>
                                <bf:Status>
                                    <xsl:attribute name="rdf:about"
                                        >http://id.loc.gov/vocabulary/mstatus/current</xsl:attribute>
                                    <rdfs:label>current</rdfs:label>
                                </bf:Status>
                            </bf:status>
                        </xsl:when>
                        <xsl:when test="substring(., 7, 1) = 'd'">
                            <bf:status>
                                <bf:Status>
                                    <xsl:attribute name="rdf:about"
                                        >http://id.loc.gov/vocabulary/mstatus/ceased</xsl:attribute>
                                    <rdfs:label>ceased</rdfs:label>
                                </bf:Status>
                            </bf:status>
                        </xsl:when>
                    </xsl:choose>
                    <xsl:if test="$pubPlace != '' and $pubPlace != '|||'">
                        <xsl:variable name="pubPlaceEncoded">
                            <xsl:call-template name="url-encode">
                                <xsl:with-param name="str" select="normalize-space($pubPlace)"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <bf:place>
                            <xsl:attribute name="rdf:resource">
                                <xsl:value-of select="concat($countries, $pubPlaceEncoded)"/>
                            </xsl:attribute>
                        </bf:place>
                    </xsl:if>
                </paGroup>
                <xsl:choose>
                    <xsl:when test="substring(., 7, 1) = 'p'">
                        <paGroup>
                            <type>Production</type>
                            <bf:date>
                                <xsl:attribute name="rdf:datatype">
                                    <xsl:value-of select="concat($edtf, 'edtf')"/>
                                </xsl:attribute>
                                <xsl:call-template name="u2x">
                                    <xsl:with-param name="dateString" select="substring(., 12, 4)"/>
                                </xsl:call-template>
                            </bf:date>
                        </paGroup>
                    </xsl:when>
                    <xsl:when test="substring(., 7, 1) = 't'">
                        <paGroup>
                            <type>Copyright</type>
                            <bf:copyrightDate>
                                <xsl:attribute name="rdf:datatype">
                                    <xsl:value-of select="concat($edtf, 'edtf')"/>
                                </xsl:attribute>
                                <xsl:call-template name="u2x">
                                    <xsl:with-param name="dateString" select="substring(., 12, 4)"/>
                                </xsl:call-template>
                            </bf:copyrightDate>
                        </paGroup>
                    </xsl:when>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test="$pubPlace != '' and $pubPlace != '|||'">
                    <xsl:variable name="pubPlaceEncoded">
                        <xsl:call-template name="url-encode">
                            <xsl:with-param name="str" select="normalize-space($pubPlace)"/>
                        </xsl:call-template>
                    </xsl:variable>
                    <paGroup>
                        <type>Publication</type>
                        <bf:place>
                            <xsl:attribute name="rdf:resource">
                                <xsl:value-of select="concat($countries, $pubPlaceEncoded)"/>
                            </xsl:attribute>
                        </bf:place>
                    </paGroup>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>
