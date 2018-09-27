#include <ESP8266WiFi.h>

void(*_smartmeter_callback)(String,String);

void smartmeter_init(void(*callback)(String,String))
{
  _smartmeter_callback = callback;
  

  Serial.setRxBufferSize(2048); 
  Serial.begin(115200);  //Init serial 115200 baud
  Serial.setDebugOutput(false);

  U0C0 = BIT(UCRXI) | BIT(UCBN) | BIT(UCBN + 1) | BIT(UCSBN); // Inverse RX

}

int8_t smartmeter_handle()
{
  float value = 0;
  int8_t returnvalue = 0;
  int day, month, year, hour, minute, second;
  char summerwinter;
  static char buffer[1000];
  static uint16_t bufpos = 0;

  while (Serial.available()) {
    char input = Serial.read() & 127;
    // Fill buffer up to and including a new line (\n)
    buffer[bufpos] = input;
    bufpos++;
    buffer[bufpos] = 0;

    if (input == '\n')
    { // We received a new line (data up to \n)
      buffer[bufpos - 1] = 0; // Remove newline character
//      if (Debug.isActive(Debug.VERBOSE)) {
//        DEBUG("RECEIVED FROM SERIAL:%s\n", buffer);
//      }
      if (buffer[0] == '/')
      {
        _smartmeter_callback("status", "receiving");
      }

      if (buffer[0] == '!')
      {
        _smartmeter_callback("status", "ready");
      }


      // 1-0:1.8.1 = Electricity low tarif used
      if (sscanf(buffer, "1-0:1.8.1(%f" , &value) == 1)
      {
        _smartmeter_callback("electricity/kwh_used1", String(value, 3));
        returnvalue++;
      }

      // 1-0:1.8.2 = Electricity high tarif used (DSMR v4.0)
      if (sscanf(buffer, "1-0:1.8.2(%f" , &value) == 1)
      {
        _smartmeter_callback("electricity/kwh_used2", String(value, 3));
        returnvalue++;
      }

      // 1-0:2.8.1 = Electricity low tarif provided
      if (sscanf(buffer, "1-0:2.8.1(%f" , &value) == 1)
      {
        _smartmeter_callback("electricity/kwh_provided1", String(value, 3));
        returnvalue++;
      }

      // 1-0:2.8.2 = Electricity high tarif provided (DSMR v4.0)
      if (sscanf(buffer, "1-0:2.8.2(%f" , &value) == 1)
      {
        _smartmeter_callback("electricity/kwh_provided2", String(value, 3));
        returnvalue++;
      }

      // 1-0:1.7.0 = Electricity actual usage (DSMR v4.0)
      if (sscanf(buffer, "1-0:1.7.0(%f" , &value) == 1)
      {
        _smartmeter_callback("electricity/kw_using", String(value, 3));
        returnvalue++;
      }

      // 1-0:2.7.0 = Electricity actual providing (DSMR v4.0)
      if (sscanf(buffer, "1-0:2.7.0(%f" , &value) == 1)
      {
        _smartmeter_callback("electricity/kw_providing", String(value, 3));
        returnvalue++;
      }

      // 0-1:24.2.1 = Gas (DSMR v4.0)
      if (sscanf(buffer, "0-1:24.2.1(%2d%2d%2d%2d%2d%2d%c)(%f", &day, &month, &year, &hour, &minute, &second, &summerwinter, &value) == 8)
      {
        _smartmeter_callback("gas/m3", String(value, 3));
        char gasdatetime[20];
        sprintf(gasdatetime, "%02ld-%02ld-%02ld %ld:%02ld:%02ld", day, month, year, hour, minute, second);
        _smartmeter_callback("gas/datetime", String(gasdatetime));
        returnvalue += 2;
      }

      buffer[0] = 0;
      bufpos = 0;
    }
    yield();
  }
  return returnvalue;
}
