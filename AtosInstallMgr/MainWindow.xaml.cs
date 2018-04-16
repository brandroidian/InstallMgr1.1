using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;
using System.Xml;


namespace AtosInstallMgr
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        private void SearchValue(string matchValue)
        {
            var colBind = ((DataGridTextColumn)dataGrid.Columns[1]).Binding as Binding;

            Func<object, Binding, object> getValue = (srcObj, bind) =>
            {
                var cntrl = new UserControl();
                cntrl.DataContext = srcObj;
                cntrl.SetBinding(UserControl.ContentProperty, bind);
                return cntrl.GetValue(UserControl.ContentProperty);
            };

            foreach (var data in dataGrid.Items)
            {
                var value = getValue(data, colBind);
                if (value == matchValue)
                {
                    dataGrid.SelectedItem = data;
                    dataGrid.ScrollIntoView(data);

                    break;
                }
            }
        }
        public MainWindow()
        {
            InitializeComponent();
        }
        
    }

   

}


