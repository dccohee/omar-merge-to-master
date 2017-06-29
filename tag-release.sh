#!/bin/bash
pushd `dirname $0` >/dev/null
SCRIPT_DIR=`pwd -P`
popd >/dev/null

echo "ABOUT TO CHECKOUT FILES"
for file in $RADIANTBLUE_FILES ; do
  if [ ! -e $file ] ; then
    checkoutFile $RADIANTBLUE_URL $file  $file
  fi
done

for file in $OSSIMLABS_FILES ; do
  if [ ! -e $file ] ; then
    checkoutFile $OSSIMLABS_URL $file $file
  fi
done

if [ ! -e oldmar ] ; then
    checkoutFile $RADIANTBLUE_URL omar oldmar
fi