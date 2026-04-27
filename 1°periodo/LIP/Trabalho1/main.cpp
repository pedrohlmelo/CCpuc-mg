/* TRABALHO SEMAFORO LIP*/
const int sensorLuz = A0;
const int ledVermelhoCarro = 2;
const int ledAmareloCarro = 3;
const int ledVerdeCarro = 4;
const int ledVermelhoPedestre = 5;
const int ledVerdePedestre = 6;
const int buzzer = 7;
const int botao = 8;


const unsigned long tempoVermelho = 8000;
const unsigned long tempoAmarelo = 2000;
const unsigned long tempoVerde = 13000;
const unsigned long tempoPedestreVerde = 8000;
const unsigned long tempoPedestreExtra = 2000;

void setup() {
  Serial.begin(9600);
  pinMode(sensorLuz, INPUT);
  pinMode(ledVermelhoCarro, OUTPUT);
  pinMode(ledAmareloCarro, OUTPUT);
  pinMode(ledVerdeCarro, OUTPUT);
  pinMode(ledVermelhoPedestre, OUTPUT);
  pinMode(ledVerdePedestre, OUTPUT);
  pinMode(buzzer, OUTPUT);
  pinMode(botao, INPUT);
}

void loop() {
  int luz = analogRead(sensorLuz);

  if (luz > 500) {
    modoDia();
  } else {
    modoNoite();
  }
}

void modoDia() {
  
  digitalWrite(ledVermelhoCarro, HIGH);
  digitalWrite(ledAmareloCarro, LOW);
  digitalWrite(ledVerdeCarro, LOW);
  digitalWrite(ledVerdePedestre, HIGH);
  digitalWrite(ledVermelhoPedestre, LOW);
  tone(buzzer, 1000); 
  delay(tempoPedestreVerde + tempoPedestreExtra); 
  noTone(buzzer);

  
  digitalWrite(ledVerdePedestre, LOW);
  digitalWrite(ledVermelhoPedestre, HIGH);

  
  digitalWrite(ledVermelhoCarro, LOW);
  digitalWrite(ledVerdeCarro, HIGH);
  delay(tempoVerde);

  
  digitalWrite(ledVerdeCarro, LOW);
  digitalWrite(ledAmareloCarro, HIGH);
  delay(tempoAmarelo);
  digitalWrite(ledAmareloCarro, LOW);

  
  unsigned long tempoInicio = millis();
  while (millis() - tempoInicio < 3000) {
    if (digitalRead(botao) == HIGH) {
      
      return;
    }
    delay(10);
  }

  
}

void modoNoite() {
  
  digitalWrite(ledVermelhoCarro, LOW);
  digitalWrite(ledVerdeCarro, LOW);
  digitalWrite(ledVerdePedestre, LOW);
  digitalWrite(ledVermelhoPedestre, HIGH); 
  digitalWrite(ledAmareloCarro, HIGH);
  delay(500);
  digitalWrite(ledAmareloCarro, LOW);
  delay(500);
}
