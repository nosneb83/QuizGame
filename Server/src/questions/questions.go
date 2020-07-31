package questions

import (
	"bufio"
	"encoding/csv"
	"io"
	"log"
	"os"
)

// QuestionObj ...
type QuestionObj struct {
	Domain string
	Difcty string
	QType  string
	Ques   []string
	Ans    []string
}

// ReadQuestionsFromCSV ...
func ReadQuestionsFromCSV() []QuestionObj {
	csvFile, _ := os.Open("QuestionList.csv")
	reader := csv.NewReader(bufio.NewReader(csvFile))
	var questions []QuestionObj
	// 略過第一列
	_, error := reader.Read()
	if error == io.EOF {
		return questions
	} else if error != nil {
		log.Fatal(error)
	}
	for {
		// 讀檔
		line, error := reader.Read()
		if error == io.EOF {
			break
		} else if error != nil {
			log.Fatal(error)
		}
		// 分不同題型
		var q, a []string
		switch line[2] {
		case "TF": // 是非題
			q = []string{line[3]}
			a = []string{line[4]}
		case "CH": // 選擇題
			q = []string{line[3]}
			a = []string{line[4], line[5], line[6], line[7]}
		case "CL": // 聯想題
			q = []string{line[3], line[4], line[5]}
			a = []string{line[6], line[7], line[8], line[9]}
		}
		questions = append(questions, QuestionObj{
			Domain: line[0],
			Difcty: line[1],
			QType:  line[2],
			Ques:   q,
			Ans:    a})
	}
	return questions
}
