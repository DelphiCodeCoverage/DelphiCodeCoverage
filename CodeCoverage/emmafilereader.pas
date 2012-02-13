unit emmafilereader;

interface

procedure readEmmaFile(path: String);

implementation

uses emmafile, sysutils;

procedure readEmmaFile(path: String);
var
  myFile: File;
  outFile : File;
  emmafile: TEmmaFile;
begin
  FileMode := fmOpenRead;

  AssignFile(myFile, path);
  reset(myFile, 1);
  emmafile := TEmmaFile.create;
  emmafile.read(myFile);

  // Close the file
  CloseFile(myFile);
  FileMode := fmOpenReadWrite;
  AssignFile(outFile, 'C:\Users\chris\out.es');
  try
    rewrite(outFile,1);
    emmafile.write(outFile);
  finally
    CloseFile(outFile);
  end;
end;

end.
