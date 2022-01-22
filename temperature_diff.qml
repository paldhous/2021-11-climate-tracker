<!DOCTYPE qgis PUBLIC 'http://mrcc.com/qgis.dtd' 'SYSTEM'>
<qgis hasScaleBasedVisibilityFlag="0" version="3.4.11-Madeira" styleCategories="AllStyleCategories" maxScale="0" minScale="1e+08">
  <flags>
    <Identifiable>1</Identifiable>
    <Removable>1</Removable>
    <Searchable>1</Searchable>
  </flags>
  <customproperties>
    <property key="WMSBackgroundLayer" value="false"/>
    <property key="WMSPublishDataSourceUrl" value="false"/>
    <property key="embeddedWidgets/count" value="0"/>
    <property key="identify/format" value="Value"/>
  </customproperties>
  <pipe>
    <rasterrenderer alphaBand="-1" classificationMin="-3.5" opacity="1" type="singlebandpseudocolor" classificationMax="3.5" band="1">
      <rasterTransparency/>
      <minMaxOrigin>
        <limits>None</limits>
        <extent>WholeRaster</extent>
        <statAccuracy>Estimated</statAccuracy>
        <cumulativeCutLower>0.02</cumulativeCutLower>
        <cumulativeCutUpper>0.98</cumulativeCutUpper>
        <stdDevFactor>2</stdDevFactor>
      </minMaxOrigin>
      <rastershader>
        <colorrampshader colorRampType="DISCRETE" classificationMode="2" clip="0">
          <colorramp type="gradient" name="[source]">
            <prop v="44,123,182,255" k="color1"/>
            <prop v="215,25,28,255" k="color2"/>
            <prop v="0" k="discrete"/>
            <prop v="gradient" k="rampType"/>
            <prop v="0.25;171,217,233,255:0.5;255,255,191,255:0.75;253,174,97,255" k="stops"/>
          </colorramp>
          <item color="#2c7bb6" alpha="255" value="-2.5" label="&lt;= -2.5"/>
          <item color="#81bad8" alpha="255" value="-1.5" label="-2.5 - -1.5"/>
          <item color="#c7e6db" alpha="255" value="-0.5" label="-1.5 - -0.5"/>
          <item color="#ffffbf" alpha="255" value="0.5" label="-0.5 - 0.5"/>
          <item color="#fec980" alpha="255" value="1.5" label="0.5 - 1.5"/>
          <item color="#f17c4a" alpha="255" value="2.5" label="1.5 - 2.5"/>
          <item color="#d7191c" alpha="255" value="inf" label="> 2.5"/>
        </colorrampshader>
      </rastershader>
    </rasterrenderer>
    <brightnesscontrast brightness="0" contrast="0"/>
    <huesaturation grayscaleMode="0" colorizeOn="0" colorizeStrength="100" colorizeBlue="128" colorizeGreen="128" colorizeRed="255" saturation="0"/>
    <rasterresampler maxOversampling="2"/>
  </pipe>
  <blendMode>0</blendMode>
</qgis>
