#!/bin/bash

# Get file names and revision
PROJECT_FILE=$(ls *.kicad_pro)
PROJECT=$(basename ${PROJECT_FILE} .kicad_pro)
PCB_FILE=$(ls ${PROJECT}.kicad_pcb)
SCH_FILE=$(ls ${PROJECT}.kicad_sch)
REVISION=$(cat $SCH_FILE | grep rev | sed 's/[(rev")]//g' | tr -d '[[:space:]]')
OUTPUT_DIR=outputs/${PROJECT}_rev${REVISION}
# Create output folders
mkdir -p ${OUTPUT_DIR}/bom \
    ${OUTPUT_DIR}/prints \
    ${OUTPUT_DIR}/gerber \
    ${OUTPUT_DIR}/pos \
    ${OUTPUT_DIR}/3d
# Generate schematics
kicad-cli sch export pdf \
    -o "${OUTPUT_DIR}/prints/${PROJECT}_rev${REVISION}_schematics.pdf" \
    ${SCH_FILE}
# Generate BOM
kicad-cli sch export bom \
    -o "${OUTPUT_DIR}/bom/${PROJECT}_rev${REVISION}_bom.csv" \
    --exclude-dnp \
    ${SCH_FILE}
# Generate Gerber files
kicad-cli pcb export gerbers \
    -o "${OUTPUT_DIR}/gerber" \
    -l F.Cu,F.Mask,F.Paste,F.Silkscreen,B.Cu,B.Mask,B.Paste,B.Silkscreen,Edge.Cuts \
    --ev \
    --no-x2 \
    --subtract-soldermask \
    --disable-aperture-macros \
    ${PCB_FILE}
# Generate drill files
kicad-cli pcb export drill \
    -o "${OUTPUT_DIR}/gerber" \
    --format excellon \
    --excellon-oval-format alternate \
    -u mm \
    --generate-map \
    --map-format gerberx2 \
    --excellon-separate-th \
    ${PCB_FILE}
# Generate position files
kicad-cli pcb export pos \
    -o "${OUTPUT_DIR}/pos/${PROJECT}_rev${REVISION}_cpl.csv" \
    --format csv \
    --units mm \
    --smd-only \
    ${PCB_FILE}
# Generate 3D model
kicad-cli pcb export step \
    --grid-origin \
    --subst-models \
    -o "${OUTPUT_DIR}/3d/${PROJECT}_rev${REVISION}_3d.step" \
    ${PCB_FILE}
# Zip everything
cd outputs/${PROJECT}_rev${REVISION}/gerber
zip jlcpcb_gerber.zip *
cd ../..
zip -r ${PROJECT}_v${REVISION}.zip ${PROJECT}_rev${REVISION}
rm -rf ${PROJECT}_rev${REVISION}
