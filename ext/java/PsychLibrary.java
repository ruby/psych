/***** BEGIN LICENSE BLOCK *****
 * Version: EPL 1.0/GPL 2.0/LGPL 2.1
 *
 * The contents of this file are subject to the Eclipse Public
 * License Version 1.0 (the "License"); you may not use this file
 * except in compliance with the License. You may obtain a copy of
 * the License at http://www.eclipse.org/legal/epl-v10.html
 *
 * Software distributed under the License is distributed on an "AS
 * IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
 * implied. See the License for the specific language governing
 * rights and limitations under the License.
 *
 * Copyright (C) 2010 Charles O Nutter <headius@headius.com>
 *
 * Alternatively, the contents of this file may be used under the terms of
 * either of the GNU General Public License Version 2 or later (the "GPL"),
 * or the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the GPL or the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of either the GPL or the LGPL, and not to allow others to
 * use your version of this file under the terms of the EPL, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL or the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the EPL, the GPL or the LGPL.
 ***** END LICENSE BLOCK *****/
package org.jruby.ext.psych;

import java.io.InputStream;
import java.io.IOException;
import java.util.Properties;

import org.jcodings.Encoding;
import org.jcodings.specific.UTF16BEEncoding;
import org.jcodings.specific.UTF16LEEncoding;
import org.jcodings.specific.UTF8Encoding;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyModule;
import org.jruby.RubyString;
import org.jruby.internal.runtime.methods.JavaMethod.JavaMethodZero;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.Visibility;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.runtime.load.Library;

public class PsychLibrary implements Library {
    public void load(final Ruby runtime, boolean wrap) {
        RubyModule psych = runtime.defineModule("Psych");

        // load version from properties packed with the jar
        Properties props = new Properties();
        try( InputStream is = runtime.getJRubyClassLoader().getResourceAsStream("META-INF/maven/org.yaml/snakeyaml/pom.properties") ) {
            props.load(is);
        }
        catch( IOException e ) {
            // ignored
        }
        String snakeyamlVersion = props.getProperty("version", "0.0");

        if (snakeyamlVersion.endsWith("-SNAPSHOT")) {
            snakeyamlVersion = snakeyamlVersion.substring(0, snakeyamlVersion.length() - "-SNAPSHOT".length());
        }

        final RubyString version = runtime.newString(snakeyamlVersion);
        version.setFrozen(true);
        psych.setConstant("SNAKEYAML_VERSION", version);

        psych.getSingletonClass().addMethod("libyaml_version", new JavaMethodZero(psych, Visibility.PUBLIC) {
            @Override
            public IRubyObject call(ThreadContext context, IRubyObject self, RubyModule clazz, String name) {
                String[] parts = version.toString().split("\\.");
                return runtime.newArray(parseInt(runtime, parts, 0), parseInt(runtime, parts, 1), parseInt(runtime, parts, 2));
            }
        });

        PsychParser.initPsychParser(runtime, psych);
        PsychEmitter.initPsychEmitter(runtime, psych);
        PsychToRuby.initPsychToRuby(runtime, psych);
        PsychYamlTree.initPsychYamlTree(runtime, psych);
    }

    private static IRubyObject parseInt(final Ruby runtime, String[] parts, int i) {
        if (i < parts.length) {
            try {
                return runtime.newFixnum(Integer.parseInt(parts[i]));
            } catch (NumberFormatException ex) { /* ignore - fallback to 0 */ }
        }
        return runtime.newFixnum(0);
    }

    public enum YAMLEncoding {
        YAML_ANY_ENCODING(UTF8Encoding.INSTANCE),
        YAML_UTF8_ENCODING(UTF8Encoding.INSTANCE),
        YAML_UTF16LE_ENCODING(UTF16LEEncoding.INSTANCE),
        YAML_UTF16BE_ENCODING(UTF16BEEncoding.INSTANCE);

        YAMLEncoding(Encoding encoding) {
            this.encoding = encoding;
        }

        public final Encoding encoding;
    }
}
