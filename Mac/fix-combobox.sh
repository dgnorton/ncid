#! /bin/sh

patch -b -d /Library/Tcl/tile0.8.3 << 'EOF'
--- combobox.tcl.original	2013-03-15 11:55:58.000000000 -0400
+++ combobox.tcl	2013-03-15 12:17:24.843301604 -0400
@@ -319,9 +319,7 @@
 	}
 	aqua {
 	    $w configure -relief solid -borderwidth 0
-	    tk::unsupported::MacWindowStyle style $w \
-	    	help {noActivates hideOnSuspend}
-	    wm resizable $w 0 0
+	    wm overrideredirect $w true
 	}
     }
     return $w
EOF
