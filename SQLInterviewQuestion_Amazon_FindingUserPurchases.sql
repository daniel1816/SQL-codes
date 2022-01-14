/*Finding User Purchases
Write a query that'll identify returning active users. A returning active user is a user that has made a second purchase within 7 days of any other of their purchases. Output a list of user_ids of these returning active users.
table:
amazon_transactions 
idint				int
user_idint			int
itemvarchar			varchar
created_atdatetime  datetime
revenueint			int

Thought process:
1. In this case, first we need to self join the table as compare the day different between transications
2. We need to group by user_id
3. Add requirement that the date different is less than 7 days
*/

SELECT DISTINCT(a1.user_id)
FROM amazon_transactions a1
JOIN amazon_transactions a2 ON a1.user_id=a2.user_id
AND a1.id <> a2.id
AND DATEDIFF(DAY, a2.created_at, a1.created_at, ) BETWEEN 0 AND 7
ORDER BY a1.user_id