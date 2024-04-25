# virtual-kitchen-sql
This project uses simulated data with advanced SQL to answer questions for Virtual Kitchen business. Snowflake is the datawarehouse hosting the data schema and executing SQL queries. 

Virtual Kitchen is an interactive meal-delivery service. Virtual Kitchen currently operates in the United States. We need to use the city and state to identify the locations of our customers and suppliers.

Virtual Kitchen has three types of users:

**Chefs**: Chefs upload their favorite recipes and then receive points each time a customer orders one of their recipes. <br>
**Customers**: Customers order from recipes in the database, and the ingredients for each recipe are shipped to their address. <br>
**Suppliers**: Suppliers package the ingredients for the recipes and ship them to customers. <br>
