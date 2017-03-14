function out = readstream(inStream)
%READSTREAM Read all bytes from stream to uint8
try
    import com.mathworks.mlwidgets.io.InterruptibleStreamCopier;
    byteStream = java.io.ByteArrayOutputStream();
    isc = InterruptibleStreamCopier.getInterruptibleStreamCopier();
    isc.copyStream(inStream, byteStream);
    inStream.close();
    byteStream.close();
    out = typecast(byteStream.toByteArray', 'uint8'); %'
catch err
    out = []; %HACK: quash
end