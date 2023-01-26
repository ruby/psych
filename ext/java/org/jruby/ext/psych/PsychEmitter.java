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

import org.jcodings.Encoding;
import org.jcodings.specific.UTF8Encoding;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyBoolean;
import org.jruby.RubyClass;
import org.jruby.RubyEncoding;
import org.jruby.RubyModule;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.util.ByteList;
import org.jruby.util.IOOutputStream;
import org.jruby.util.TypeConverter;
import org.jruby.util.io.EncodingUtils;
import org.snakeyaml.engine.v2.api.DumpSettings;
import org.snakeyaml.engine.v2.api.DumpSettingsBuilder;
import org.snakeyaml.engine.v2.api.StreamDataWriter;
import org.snakeyaml.engine.v2.api.YamlOutputStreamWriter;
import org.snakeyaml.engine.v2.common.Anchor;
import org.snakeyaml.engine.v2.common.FlowStyle;
import org.snakeyaml.engine.v2.common.ScalarStyle;
import org.snakeyaml.engine.v2.common.SpecVersion;
import org.snakeyaml.engine.v2.emitter.Emitter;
import org.snakeyaml.engine.v2.events.AliasEvent;
import org.snakeyaml.engine.v2.events.DocumentEndEvent;
import org.snakeyaml.engine.v2.events.DocumentStartEvent;
import org.snakeyaml.engine.v2.events.Event;
import org.snakeyaml.engine.v2.events.ImplicitTuple;
import org.snakeyaml.engine.v2.events.MappingEndEvent;
import org.snakeyaml.engine.v2.events.MappingStartEvent;
import org.snakeyaml.engine.v2.events.ScalarEvent;
import org.snakeyaml.engine.v2.events.SequenceEndEvent;
import org.snakeyaml.engine.v2.events.SequenceStartEvent;
import org.snakeyaml.engine.v2.events.StreamEndEvent;
import org.snakeyaml.engine.v2.events.StreamStartEvent;
import org.snakeyaml.engine.v2.exceptions.EmitterException;
import org.snakeyaml.engine.v2.exceptions.Mark;

import java.io.IOException;
import java.nio.charset.Charset;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

import static org.jruby.runtime.Visibility.PRIVATE;

public class PsychEmitter extends RubyObject {
    public static void initPsychEmitter(Ruby runtime, RubyModule psych) {
        RubyClass psychHandler = runtime.defineClassUnder("Handler", runtime.getObject(), runtime.getObject().getAllocator(), psych);
        RubyClass psychEmitter = runtime.defineClassUnder("Emitter", psychHandler, PsychEmitter::new, psych);

        psychEmitter.defineAnnotatedMethods(PsychEmitter.class);
    }

    public PsychEmitter(Ruby runtime, RubyClass klass) {
        super(runtime, klass);
    }

    @JRubyMethod(visibility = PRIVATE)
    public IRubyObject initialize(ThreadContext context, IRubyObject io) {
        dumpSettingsBuilder.setIndent(2);

        this.io = io;

        return context.nil;
    }

    @JRubyMethod(visibility = PRIVATE)
    public IRubyObject initialize(ThreadContext context, IRubyObject io, IRubyObject rbOptions) {
        IRubyObject width     = rbOptions.callMethod(context, "line_width");
        IRubyObject canonical = rbOptions.callMethod(context, "canonical");
        IRubyObject level     = rbOptions.callMethod(context, "indentation");

        dumpSettingsBuilder.setCanonical(canonical.isTrue());
        dumpSettingsBuilder.setIndent((int)level.convertToInteger().getLongValue());
        line_width_set(context, width);

        this.io = io;

        return context.nil;
    }

    @JRubyMethod
    public IRubyObject start_stream(ThreadContext context, IRubyObject encoding) {
        TypeConverter.checkType(context, encoding, context.runtime.getFixnum());

        initEmitter(context, encoding);

        emit(context, NULL_STREAM_START_EVENT);

        return this;
    }

    @JRubyMethod
    public IRubyObject end_stream(ThreadContext context) {
        emit(context, NULL_STREAM_START_EVENT);
        return this;
    }

    @JRubyMethod
    public IRubyObject start_document(ThreadContext context, IRubyObject _version, IRubyObject tags, IRubyObject implicit) {
        Ruby runtime = context.runtime;

        boolean implicitBool = implicit.isTrue();

        RubyClass arrayClass = runtime.getArray();
        TypeConverter.checkType(context, _version, arrayClass);

        RubyArray versionAry = _version.convertToArray();
        Optional<SpecVersion> specVersion;
        if (versionAry.size() == 2) {
            int versionInt0 = versionAry.eltInternal(0).convertToInteger().getIntValue();
            int versionInt1 = versionAry.eltInternal(1).convertToInteger().getIntValue();

            if (versionInt0 != 1) {
                throw runtime.newArgumentError("invalid YAML version: " + versionAry);
            }

            specVersion = Optional.of(new SpecVersion(versionInt0, versionInt1));
        } else {
            specVersion = Optional.empty();
        }

        Map<String, String> tagsMap = new HashMap<>();

        if (!tags.isNil()) {
            TypeConverter.checkType(context, tags, arrayClass);

            RubyArray tagsAry = tags.convertToArray();
            if (tagsAry.size() > 0) {
                tagsMap = new HashMap<>(tagsAry.size());
                for (int i = 0; i < tagsAry.size(); i++) {
                    RubyArray tagsTuple = tagsAry.eltInternal(i).convertToArray();
                    if (tagsTuple.size() != 2) {
                        throw runtime.newRuntimeError("tags tuple must be of length 2");
                    }
                    IRubyObject key = tagsTuple.eltInternal(0);
                    IRubyObject value = tagsTuple.eltInternal(1);
                    tagsMap.put(
                            key.asJavaString(),
                            value.asJavaString());
                }
            }
        }

        DocumentStartEvent event = new DocumentStartEvent(!implicitBool, specVersion, tagsMap, NULL_MARK, NULL_MARK);
        emit(context, event);
        return this;
    }

    @JRubyMethod
    public IRubyObject end_document(ThreadContext context, IRubyObject implicit) {
        DocumentEndEvent event = new DocumentEndEvent(!implicit.isTrue(), NULL_MARK, NULL_MARK);
        emit(context, event);
        return this;
    }

    @JRubyMethod(required = 6)
    public IRubyObject scalar(ThreadContext context, IRubyObject[] args) {
        IRubyObject value = args[0];
        IRubyObject anchor = args[1];
        IRubyObject tag = args[2];
        IRubyObject plain = args[3];
        IRubyObject quoted = args[4];
        IRubyObject style = args[5];

        RubyClass stringClass = context.runtime.getString();

        TypeConverter.checkType(context, value, stringClass);

        RubyString valueStr = (RubyString) value;

        valueStr = EncodingUtils.strConvEnc(context, valueStr, valueStr.getEncoding(), UTF8Encoding.INSTANCE);

        String anchorStr = exportToUTF8(context, anchor, stringClass);
        String tagStr = exportToUTF8(context, tag, stringClass);

        ScalarEvent event = new ScalarEvent(
                Optional.ofNullable(anchorStr == null ? null : new Anchor(anchorStr)),
                Optional.ofNullable(tagStr),
                new ImplicitTuple(plain.isTrue(), quoted.isTrue()),
                valueStr.asJavaString(),
                SCALAR_STYLES[style.convertToInteger().getIntValue()],
                NULL_MARK,
                NULL_MARK);

        emit(context, event);

        return this;
    }

    @JRubyMethod(required = 4)
    public IRubyObject start_sequence(ThreadContext context, IRubyObject[] args) {
        IRubyObject anchor = args[0];
        IRubyObject tag = args[1];
        IRubyObject implicit = args[2];
        IRubyObject style = args[3];

        RubyClass stringClass = context.runtime.getString();

        String anchorStr = exportToUTF8(context, anchor, stringClass);
        String tagStr = exportToUTF8(context, tag, stringClass);

        SequenceStartEvent event = new SequenceStartEvent(
                Optional.ofNullable(anchorStr == null ? null : new Anchor(anchorStr)),
                Optional.ofNullable(tagStr),
                implicit.isTrue(),
                FLOW_STYLES[style.convertToInteger().getIntValue()],
                NULL_MARK,
                NULL_MARK);
        emit(context, event);
        return this;
    }

    @JRubyMethod
    public IRubyObject end_sequence(ThreadContext context) {
        SequenceEndEvent event = new SequenceEndEvent(NULL_MARK, NULL_MARK);
        emit(context, event);
        return this;
    }

    @JRubyMethod(required = 4)
    public IRubyObject start_mapping(ThreadContext context, IRubyObject[] args) {
        IRubyObject anchor = args[0];
        IRubyObject tag = args[1];
        IRubyObject implicit = args[2];
        IRubyObject style = args[3];

        RubyClass stringClass = context.runtime.getString();

        String anchorStr = exportToUTF8(context, anchor, stringClass);
        String tagStr = exportToUTF8(context, tag, stringClass);

        MappingStartEvent event = new MappingStartEvent(
                Optional.ofNullable(anchorStr == null ? null : new Anchor(anchorStr)),
                Optional.ofNullable(tagStr),
                implicit.isTrue(),
                FLOW_STYLES[style.convertToInteger().getIntValue()],
                NULL_MARK,
                NULL_MARK);

        emit(context, event);

        return this;
    }

    @JRubyMethod
    public IRubyObject end_mapping(ThreadContext context) {
        MappingEndEvent event = new MappingEndEvent(NULL_MARK, NULL_MARK);
        emit(context, event);
        return this;
    }
    
    @JRubyMethod
    public IRubyObject alias(ThreadContext context, IRubyObject anchor) {
        RubyClass stringClass = context.runtime.getString();

        String anchorStr = exportToUTF8(context, anchor, stringClass);

        AliasEvent event = new AliasEvent(Optional.of(new Anchor(anchorStr)), NULL_MARK, NULL_MARK);
        emit(context, event);
        return this;
    }

    @JRubyMethod(name = "canonical=")
    public IRubyObject canonical_set(ThreadContext context, IRubyObject canonical) {
        // TODO: unclear if this affects a running emitter
        dumpSettingsBuilder.setCanonical(canonical.isTrue());
        return canonical;
    }

    @JRubyMethod
    public IRubyObject canonical(ThreadContext context) {
        // TODO: unclear if this affects a running emitter
        return RubyBoolean.newBoolean(context, buildDumpSettings().isCanonical());
    }

    @JRubyMethod(name = "indentation=")
    public IRubyObject indentation_set(ThreadContext context, IRubyObject level) {
        // TODO: unclear if this affects a running emitter
        dumpSettingsBuilder.setIndent(level.convertToInteger().getIntValue());
        return level;
    }

    @JRubyMethod
    public IRubyObject indentation(ThreadContext context) {
        // TODO: unclear if this affects a running emitter
        return context.runtime.newFixnum(buildDumpSettings().getIndent());
    }

    @JRubyMethod(name = "line_width=")
    public IRubyObject line_width_set(ThreadContext context, IRubyObject width) {
        int newWidth = width.convertToInteger().getIntValue();
        if (newWidth <= 0) newWidth = Integer.MAX_VALUE;
        dumpSettingsBuilder.setWidth(newWidth);
        return width;
    }

    @JRubyMethod
    public IRubyObject line_width(ThreadContext context) {
        return context.runtime.newFixnum(buildDumpSettings().getWidth());
    }

    private void emit(ThreadContext context, Event event) {
        try {
            if (emitter == null) throw context.runtime.newRuntimeError("uninitialized emitter");

            emitter.emit(event);

            // flush writer after each emit
            writer.flush();
        } catch (EmitterException ee) {
            throw context.runtime.newRuntimeError(ee.toString());
        }
    }

    private void initEmitter(ThreadContext context, IRubyObject _encoding) {
        if (emitter != null) throw context.runtime.newRuntimeError("already initialized emitter");

        Encoding encoding = PsychLibrary.YAMLEncoding.values()[(int)_encoding.convertToInteger().getLongValue()].encoding;
        Charset charset = context.runtime.getEncodingService().charsetForEncoding(encoding);

        writer = new YamlOutputStreamWriter(new IOOutputStream(io, encoding), charset) {
            @Override
            public void processIOException(IOException ioe) {
                throw context.runtime.newIOErrorFromException(ioe);
            }
        };
        emitter = new Emitter(buildDumpSettings(), writer);
    }

    private DumpSettings buildDumpSettings() {
        return dumpSettingsBuilder.build();
    }

    private String exportToUTF8(ThreadContext context, IRubyObject maybeString, RubyClass stringClass) {
        if (maybeString.isNil()) {
            return null;
        }

        RubyString string;

        TypeConverter.checkType(context, maybeString, stringClass);
        string = (RubyString) maybeString;
        ByteList bytes = string.getByteList();

        return RubyEncoding.decodeUTF8(bytes.unsafeBytes(), bytes.begin(), bytes.realSize());
    }

    Emitter emitter;
    StreamDataWriter writer;
    final DumpSettingsBuilder dumpSettingsBuilder = DumpSettings.builder();
    IRubyObject io;

    private static final Optional<Mark> NULL_MARK = Optional.empty();
    private static final StreamStartEvent NULL_STREAM_START_EVENT = new StreamStartEvent(NULL_MARK, NULL_MARK);

    // Map style constants from Psych values (ANY = 0 ... FOLDED = 5)
    // to SnakeYaml values; see psych/nodes/scalar.rb.
    private static final ScalarStyle[] SCALAR_STYLES = {
            ScalarStyle.PLAIN, // ANY
            ScalarStyle.PLAIN,
            ScalarStyle.SINGLE_QUOTED,
            ScalarStyle.DOUBLE_QUOTED,
            ScalarStyle.LITERAL,
            ScalarStyle.FOLDED
    };

    private static final FlowStyle[] FLOW_STYLES = {
            FlowStyle.AUTO,
            FlowStyle.BLOCK,
            FlowStyle.FLOW
    };
}
