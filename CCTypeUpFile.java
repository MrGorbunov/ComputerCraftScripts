/**
  (Better) MineCopy
  A Java rewrite of Kazagistar's Computercraft Minecopy V2
  http://www.computercraft.info/forums2/index.php?/topic/1963-minecopy-v2-linuxwindows/

  I couldn't get Kazagistar's version working on my end :/

  If you're playing on a server with latency, increase millisDelay. Otherwise
  you can decrease that a lot (I had some servers working with 1 millisDelay).
  Also, there's a loop that adds 1/4 second pause every 10 lines, adjust that as
  it seems fine as well.
*/

import java.awt.Robot;
import java.awt.event.KeyEvent;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.util.HashMap;
import java.util.HashSet;
import java.util.concurrent.TimeUnit;
import java.util.regex.Pattern;



public class CCTypeUpFile {

  static final long millisDelay = 10;
  // static final String fileRegex = "[^\\n\\r\\.]+\\.lua";
  static final String fileRegex = "quarry-2.1.lua";

  static Robot robot;
  static HashSet<Character> isAPerfectMatch;
  static HashMap<Character, Integer> charShiftedMapping;

  public static void main(String[] args) throws Exception {

    //
    // File Selection
    File luaFile = searchForLuaFile();

    if (luaFile == null) {
      System.err.println("No .lua file found. \nSpecifically nothing matched the regex: '" + fileRegex + "'");
      System.exit(1);
    }

    BufferedReader bufferedReader = new BufferedReader( new FileReader(luaFile));



    //
    // Pause for user to make MC window active
    System.out.println("Found file: " + luaFile.getName());
    System.out.println();
    System.out.print("Starting in 3... ");
    TimeUnit.SECONDS.sleep(1); 
    System.out.print("2... ");
    TimeUnit.SECONDS.sleep(1);
    System.out.println("1... ");
    TimeUnit.SECONDS.sleep(1);



    //
    // Main Loop
    robot = new Robot();
    initializeTypingObjects();

    String nextLine = bufferedReader.readLine();
    int i=0;

    while (nextLine != null) {
      // Indentation gets messed up inside the turtle editor
      // so its just removed
      String processedLine = nextLine.trim();
      boolean isComment = processedLine.length() >= 2  && processedLine.substring(0, 2).equals("--");
      boolean isStartOfMultiLineComment = processedLine.length() >= 4 && processedLine.substring(0, 4).equals("--[[");
      boolean isEmpty = processedLine.length() == 0;
      boolean skipLine = (isComment && !isStartOfMultiLineComment) || isEmpty;

      if (!skipLine)
        typeNextLine(processedLine + "\n");

      i++;
      if (i % 10 == 0)
        TimeUnit.MILLISECONDS.sleep(250);

      nextLine = bufferedReader.readLine();
    }

    bufferedReader.close();
  }














  // =====================================================================
  //                          Searching Logic
  // =====================================================================

  private static File searchForLuaFile () {
    File[] filesInDir = (new File("./")).listFiles();

    for (int i=0; i<filesInDir.length; i++) {
      File file = filesInDir[i];

      if (Pattern.matches(fileRegex, file.getName()))
        return file;
    }

    return null;
  }




















  // =====================================================================
  //                          Typing Logic
  // =====================================================================

  /**
   * Initializes two hashmaps used in typeOutFile. MUST be called
   * before typeOutFile
   */
  private static void initializeTypingObjects () {

    //
    // Perfect Matches

    char[] charsPerfectMatchups = {' ', '-', '=', ';', ',', '.', '/', '\\', '[', ']', '\n', '\r'};
    isAPerfectMatch = new HashSet<Character>();
    for (char c : charsPerfectMatchups)
      isAPerfectMatch.add(c);


    //
    // Characters that are another character + shift

    charShiftedMapping = new HashMap<Character, Integer> ();

    charShiftedMapping.put('!', (int) '1'); // The exclamation mark is SHIFT + '1'
    charShiftedMapping.put('@', (int) '2'); 
    charShiftedMapping.put('#', (int) '3'); 
    charShiftedMapping.put('$', (int) '4'); 
    charShiftedMapping.put('%', (int) '5'); 
    charShiftedMapping.put('^', (int) '6'); 
    charShiftedMapping.put('&', (int) '7'); 
    charShiftedMapping.put('*', (int) '8'); 
    charShiftedMapping.put('(', (int) '9'); 
    charShiftedMapping.put(')', (int) '0'); 

    charShiftedMapping.put('_', (int) '-'); 
    charShiftedMapping.put('+', (int) '='); 
    charShiftedMapping.put('{', (int) '['); 
    charShiftedMapping.put('}', (int) ']'); 
    charShiftedMapping.put('|', (int) '\\');
    charShiftedMapping.put(':', (int) ';'); 
    charShiftedMapping.put('<', (int) ','); 
    charShiftedMapping.put('>', (int) '.'); 
    charShiftedMapping.put('?', (int) '/'); 
    charShiftedMapping.put('"', (int) 222); // There's always gotta be some exceptions
    charShiftedMapping.put('~', (int) 192); // There's always gotta be some exceptions
  }



  private static void typeNextLine (String str) throws InterruptedException {
    for (char charValue : str.toCharArray()) {
      if ('a' <= charValue && charValue <= 'z')
        pressKey(charValue - 32);

      // These key codes are perfect matches but need shift pressed
      else if ('A' <= charValue && charValue <= 'Z')
        pressKeyWithShift(charValue);

      // Characters inside isAPerfectMatch and digits are perfect mapping of char int value <=> keyCode
      else if (isAPerfectMatch.contains(charValue) || ('0' <= charValue && charValue <= '9'))
        pressKey(charValue);

      // shiftedMapping need both the custom mapping and the shift key pressed down
      else if (charShiftedMapping.containsKey(charValue))
        pressKeyWithShift(charShiftedMapping.get(charValue));

      // Always gotta some special ones
      else if (charValue == '\'')
        pressKey(222);
      else if (charValue == '`')
        pressKey(192);

      // Otherwise we skip
      else
        System.out.println("[WARNING] Unrecognized character used: " + charValue);
    }
  }



  private static void pressKeyWithShift (int keyCode) throws InterruptedException {
    robot.keyPress(KeyEvent.VK_SHIFT);
    robot.keyPress(keyCode); 
    TimeUnit.MILLISECONDS.sleep(millisDelay);

    robot.keyRelease(keyCode);
    robot.keyRelease(KeyEvent.VK_SHIFT);
    TimeUnit.MILLISECONDS.sleep(millisDelay);
  }



  private static void pressKey (int keyCode) throws InterruptedException {
    robot.keyPress(keyCode); 
    TimeUnit.MILLISECONDS.sleep(millisDelay);

    robot.keyRelease(keyCode);
    TimeUnit.MILLISECONDS.sleep(millisDelay);
  }

}

